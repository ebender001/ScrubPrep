// Integration test for cloud/main.js using an in-memory fake Parse SDK and a
// stubbed https.request (so no real Parse Server or OpenAI call is made), to
// verify the Cloud Function wiring, PimpSession persistence, and the
// non-final vs. final answerPimpQuestion branches.

const { test } = require("node:test");
const assert = require("node:assert/strict");
const https = require("node:https");

let idCounter = 0;
const store = {};
let specialtiesByName = {};

class FakeParseError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

class FakeParseObject {
  constructor(className) {
    this.className = className;
    this.attributes = {};
    this.id = undefined;
    this.createdAt = undefined;
    this.updatedAt = undefined;
  }
  set(key, value) {
    this.attributes[key] = value;
  }
  get(key) {
    return this.attributes[key];
  }
  async save() {
    const now = new Date();
    if (!this.id) {
      idCounter += 1;
      this.id = `obj_${idCounter}`;
      this.createdAt = now;
      store[this.className] = store[this.className] || {};
      store[this.className][this.id] = this;
    }
    this.updatedAt = now;
    return this;
  }
  async destroy() {
    if (store[this.className]) delete store[this.className][this.id];
  }
}

class FakeParseQuery {
  constructor(className) {
    this.className = className;
    this._order = [];
    this._equalTo = {};
  }
  async get(id) {
    const obj = (store[this.className] || {})[id];
    if (!obj) throw new FakeParseError(101, "not found");
    return obj;
  }
  ascending(field) {
    this._order = [field];
    return this;
  }
  addAscending(field) {
    this._order.push(field);
    return this;
  }
  equalTo(field, value) {
    this._equalTo[field] = value;
    return this;
  }
  limit() {
    return this;
  }
  include() {
    // No-op: fake objects always hold their full attributes (including any object set as a
    // pointer value), so there's no lazy-pointer behavior to simulate here.
    return this;
  }
  async find() {
    const all = Object.values(store[this.className] || {}).filter((obj) =>
      Object.entries(this._equalTo).every(([field, value]) => {
        const actual = field === "objectId" ? obj.id : obj.get(field);
        return actual === value;
      })
    );
    return all.slice().sort((a, b) => {
      for (const field of this._order) {
        const av = field === "updatedAt" ? a.updatedAt : a.get(field);
        const bv = field === "updatedAt" ? b.updatedAt : b.get(field);
        const direction = this._descending && this._descending.has(field) ? -1 : 1;
        if (av < bv) return -1 * direction;
        if (av > bv) return 1 * direction;
      }
      return 0;
    });
  }
  descending(field) {
    this._descending = this._descending || new Set();
    this._descending.add(field);
    this._order.push(field);
    return this;
  }
  async first() {
    const results = await this.find();
    return results[0] || null;
  }
}

const registry = {};

global.Parse = {
  Object: {
    extend: (className) =>
      class extends FakeParseObject {
        constructor() {
          super(className);
        }
      },
  },
  Query: FakeParseQuery,
  Error: Object.assign(FakeParseError, {
    VALIDATION_ERROR: 141,
    OBJECT_NOT_FOUND: 101,
    OPERATION_FORBIDDEN: 119,
    INTERNAL_SERVER_ERROR: 1,
    INVALID_SESSION_TOKEN: 209,
  }),
  Cloud: {
    define: (name, handler) => {
      registry[name] = handler;
    },
    job: (name, handler) => {
      registry[name] = handler;
    },
  },
};

process.env.OPENAI_API_KEY = "test-key";

// https.request mock: pops the next canned OpenAI-shaped response off a queue.
// aiClient.js calls `https.request` directly (not global fetch), so we patch
// the core `https` module in place — it's a singleton across requires.
const responseQueue = [];
https.request = (_options, callback) => {
  const payload = responseQueue.shift();
  if (payload === undefined) throw new Error("no mock response queued");
  const body = JSON.stringify({
    choices: [{ message: { content: JSON.stringify(payload) } }],
    usage: { prompt_tokens: 100, completion_tokens: 50, total_tokens: 150 },
  });
  const res = {
    statusCode: 200,
    on(event, handler) {
      if (event === "data") handler(body);
      if (event === "end") handler();
      return res;
    },
  };
  callback(res);
  return { on: () => {}, write: () => {}, end: () => {} };
};

require("../cloud/main.js");

test("startPimpSession -> answerPimpQuestion (non-final) -> answerPimpQuestion (final)", async () => {
  responseQueue.push({ question: "What forms the hepatocystic triangle?" });
  const started = await registry.startPimpSession({
    params: {
      caseDescription: "Lap chole for acute cholecystitis",
      prep: { title: "Laparoscopic Cholecystectomy", must_know: ["Critical view of safety"] },
      difficulty: "typical",
    },
  });
  assert.equal(started.done, false);
  assert.equal(started.question, "What forms the hepatocystic triangle?");
  assert.deepEqual(started.progress, { index: 0, total: 5 });
  assert.ok(started.sessionId);

  responseQueue.push({
    assessment: "partially_correct",
    feedback: "You named two of three borders.",
    teaching_point: "It's bounded by the cystic duct, common hepatic duct, and liver edge.",
    concept: "hepatocystic triangle",
    next_question: "What artery usually runs through this region?",
  });
  const answered1 = await registry.answerPimpQuestion({
    params: { sessionId: started.sessionId, answer: "Cystic duct and common hepatic duct" },
  });
  assert.equal(answered1.done, false);
  assert.equal(answered1.assessment, "partially_correct");
  assert.equal(answered1.nextQuestion, "What artery usually runs through this region?");
  assert.deepEqual(answered1.progress, { index: 1, total: 5 });

  // Fast-forward the session to its last question by mutating stored state directly.
  const session = store.PimpSession[started.sessionId];
  session.set(
    "history",
    Array.from({ length: 4 }, (_, i) => ({
      question: `Q${i}`,
      answer: `A${i}`,
      assessment: "correct",
      concept: `concept${i}`,
    }))
  );
  session.set("pendingQuestion", "Where does the cystic artery usually arise?");

  responseQueue.push({
    assessment: "correct",
    feedback: "Correct.",
    teaching_point: "The cystic artery typically arises from the right hepatic artery.",
    concept: "cystic artery origin",
    strong: ["Indications for surgery"],
    review: ["Arterial anatomy variants"],
    two_minute_review: ["Cystic artery usually arises from the right hepatic artery."],
  });
  const finalAnswer = await registry.answerPimpQuestion({
    params: { sessionId: started.sessionId, answer: "Right hepatic artery" },
  });
  assert.equal(finalAnswer.done, true);
  assert.deepEqual(finalAnswer.progress, { index: 5, total: 5 });
  assert.deepEqual(finalAnswer.summary.strong, ["Indications for surgery"]);
  assert.equal(session.get("status"), "complete");
});

test("listCases/saveCase/markCaseReviewed/deleteCase require a signed-in user", async () => {
  await assert.rejects(() => registry.listCases({ params: {}, user: undefined }), (err) => {
    assert.equal(err.code, 209);
    return true;
  });
  await assert.rejects(
    () => registry.saveCase({ params: { caseDescription: "Lap chole", prep: {} }, user: undefined }),
    (err) => {
      assert.equal(err.code, 209);
      return true;
    }
  );
  await assert.rejects(
    () => registry.markCaseReviewed({ params: { caseId: "x" }, user: undefined }),
    (err) => {
      assert.equal(err.code, 209);
      return true;
    }
  );
  await assert.rejects(() => registry.deleteCase({ params: { caseId: "x" }, user: undefined }), (err) => {
    assert.equal(err.code, 209);
    return true;
  });
});

test("saveCase -> listCases -> markCaseReviewed -> deleteCase (cascading to Pimp Me sessions)", async () => {
  const owner = { id: "user_1" };

  const saved = await registry.saveCase({
    params: { caseDescription: "Lap chole for acute cholecystitis", prep: { title: "Lap Chole" } },
    user: owner,
  });
  assert.deepEqual(saved.case.prep, { title: "Lap Chole" });
  assert.equal(saved.case.lastReviewedAt, null);

  // Saving the same (normalized) case again updates in place rather than duplicating.
  const savedAgain = await registry.saveCase({
    params: { caseDescription: "Lap Chole For Acute Cholecystitis", prep: { title: "Lap Chole v2" } },
    user: owner,
  });
  assert.equal(savedAgain.case.id, saved.case.id);

  const listed = await registry.listCases({ params: {}, user: owner });
  assert.equal(listed.cases.length, 1);
  assert.deepEqual(listed.cases[0].prep, { title: "Lap Chole v2" });

  // A different user's cases are never visible.
  const otherOwnerListed = await registry.listCases({ params: {}, user: { id: "user_2" } });
  assert.equal(otherOwnerListed.cases.length, 0);

  const reviewed = await registry.markCaseReviewed({ params: { caseId: saved.case.id }, user: owner });
  assert.equal(reviewed.success, true);

  // A completed Pimp Me session on this same case should be cascade-deleted with it.
  await registry.savePimpMeSession({
    params: {
      caseDescription: "Lap chole for acute cholecystitis",
      difficulty: "easy",
      transcript: [{ question: "Q", answer: "A", assessment: "correct", feedback: "f", teachingPoint: "t" }],
      summary: { strong: [], review: [], twoMinuteReview: [] },
    },
    user: owner,
  });
  const sessionsBeforeDelete = await registry.listPimpMeSessions({
    params: { caseDescription: "Lap chole for acute cholecystitis" },
    user: owner,
  });
  assert.equal(sessionsBeforeDelete.sessions.length, 1);

  const deleted = await registry.deleteCase({ params: { caseId: saved.case.id }, user: owner });
  assert.equal(deleted.success, true);

  const listedAfterDelete = await registry.listCases({ params: {}, user: owner });
  assert.equal(listedAfterDelete.cases.length, 0);

  const sessionsAfterDelete = await registry.listPimpMeSessions({
    params: { caseDescription: "Lap chole for acute cholecystitis" },
    user: owner,
  });
  assert.equal(sessionsAfterDelete.sessions.length, 0);

  await assert.rejects(() => registry.deleteCase({ params: { caseId: saved.case.id }, user: owner }), (err) => {
    assert.equal(err.code, 101);
    return true;
  });
});

test("savePimpMeSession overwrites the existing row for the same (case, difficulty) instead of duplicating", async () => {
  const owner = { id: "user_3" };
  await registry.saveCase({
    params: { caseDescription: "CABG x3", prep: { title: "CABG" } },
    user: owner,
  });

  await registry.savePimpMeSession({
    params: {
      caseDescription: "CABG x3",
      difficulty: "tough",
      transcript: [{ question: "Q1", answer: "A1", assessment: "correct", feedback: "f", teachingPoint: "t" }],
      summary: { strong: [], review: [], twoMinuteReview: [] },
    },
    user: owner,
  });
  await registry.savePimpMeSession({
    params: {
      caseDescription: "CABG x3",
      difficulty: "tough",
      transcript: [
        { question: "Q1", answer: "A1", assessment: "correct", feedback: "f", teachingPoint: "t" },
        { question: "Q2", answer: "A2", assessment: "correct", feedback: "f", teachingPoint: "t" },
      ],
      summary: { strong: ["x"], review: [], twoMinuteReview: [] },
    },
    user: owner,
  });

  const { sessions } = await registry.listPimpMeSessions({
    params: { caseDescription: "CABG x3" },
    user: owner,
  });
  assert.equal(sessions.length, 1);
  assert.equal(sessions[0].transcript.length, 2);
});

test("generateScrubPrep rejects obvious PHI before calling the AI", async () => {
  await assert.rejects(
    () =>
      registry.generateScrubPrep({
        params: { caseDescription: "Lap chole, patient DOB 1/1/1980" },
      }),
    (err) => {
      assert.match(err.message, /remove patient names/);
      return true;
    }
  );
});

test("generateScrubPrep surfaces a witty, distinctly-coded error for gibberish input", async () => {
  responseQueue.push({
    recognized: false,
    title: "Unrecognized Case",
    case_summary: "Not applicable.",
    why_operating: ["Not applicable."],
    anatomy: ["Not applicable."],
    operation_overview: ["Not applicable."],
    things_to_watch: ["Not applicable."],
    complications: ["Not applicable."],
    must_know: ["Not applicable.", "x", "x", "x", "x"],
    likely_questions: [{ question: "x", answer: "x" }],
  });
  await assert.rejects(
    () => registry.generateScrubPrep({ params: { caseDescription: "asdkjfhaslkdjf qwerty" } }),
    (err) => {
      assert.equal(err.code, 4001);
      assert.ok(err.message.length > 0);
      return true;
    }
  );
});

test("generateRapidFire returns exactly 5 questions via the cloud function", async () => {
  responseQueue.push({
    questions: Array.from({ length: 5 }, (_, i) => ({ question: `Q${i}`, answer: `A${i}` })),
  });
  const result = await registry.generateRapidFire({
    params: { caseDescription: "Appendectomy", prep: { title: "Appendectomy" } },
  });
  assert.equal(result.questions.length, 5);
});

test("every AI-backed Cloud Function logs an AIUsageEvent row with token usage and cost", async () => {
  const events = Object.values(store.AIUsageEvent || {});
  assert.ok(events.length > 0, "expected at least one AIUsageEvent row from earlier tests in this file");

  const rapidFireEvent = events.find((e) => e.get("functionName") === "generateRapidFire");
  assert.ok(rapidFireEvent, "expected an AIUsageEvent for generateRapidFire");
  assert.equal(rapidFireEvent.get("promptTokens"), 100);
  assert.equal(rapidFireEvent.get("completionTokens"), 50);
  assert.equal(rapidFireEvent.get("totalTokens"), 150);
  assert.ok(rapidFireEvent.get("estimatedCostUSD") > 0);

  assert.ok(
    events.some((e) => e.get("functionName") === "startPimpSession"),
    "expected an AIUsageEvent for startPimpSession"
  );
  assert.ok(
    events.some((e) => e.get("functionName") === "answerPimpQuestion"),
    "expected an AIUsageEvent for answerPimpQuestion"
  );
});

test("listSpecialties returns catalog rows sorted by sortOrder, name", async () => {
  store.Specialty = {};
  const seed = [
    { name: "ENT", sortOrder: 4 },
    { name: "General Surgery", sortOrder: 1 },
    { name: "Cardiac Surgery", sortOrder: 2 },
  ];
  for (const attrs of seed) {
    const obj = new FakeParseObject("Specialty");
    for (const [key, value] of Object.entries(attrs)) obj.set(key, value);
    await obj.save();
    specialtiesByName[attrs.name] = obj;
  }

  const result = await registry.listSpecialties({ params: {} });
  assert.deepEqual(
    result.specialties.map((s) => s.name),
    ["General Surgery", "Cardiac Surgery", "ENT"]
  );
});

test("listCaseTypes returns catalog rows sorted by specialty, sortOrder, name, with a populated specialty pointer", async () => {
  store.CaseType = {};
  const seed = [
    { name: "Appendectomy", fullName: "Appendectomy", specialty: specialtiesByName["General Surgery"], sortOrder: 2, featured: true },
    { name: "Lap Chole", fullName: "Laparoscopic Cholecystectomy", specialty: specialtiesByName["General Surgery"], sortOrder: 1, featured: true },
    { name: "CABG", fullName: "Coronary Artery Bypass Grafting", specialty: specialtiesByName["Cardiac Surgery"], sortOrder: 1, featured: false },
  ];
  for (const attrs of seed) {
    const obj = new FakeParseObject("CaseType");
    for (const [key, value] of Object.entries(attrs)) obj.set(key, value);
    await obj.save();
  }

  const result = await registry.listCaseTypes({ params: {} });
  assert.deepEqual(result.caseTypes, [
    { name: "Lap Chole", fullName: "Laparoscopic Cholecystectomy", specialty: { id: specialtiesByName["General Surgery"].id, name: "General Surgery" }, featured: true },
    { name: "Appendectomy", fullName: "Appendectomy", specialty: { id: specialtiesByName["General Surgery"].id, name: "General Surgery" }, featured: true },
    { name: "CABG", fullName: "Coronary Artery Bypass Grafting", specialty: { id: specialtiesByName["Cardiac Surgery"].id, name: "Cardiac Surgery" }, featured: false },
  ]);
});

test("answerPimpQuestion returns a clean error for an unknown session", async () => {
  await assert.rejects(
    () => registry.answerPimpQuestion({ params: { sessionId: "does_not_exist", answer: "x" } }),
    (err) => {
      assert.match(err.message, /session was not found/);
      return true;
    }
  );
});
