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
  }
  set(key, value) {
    this.attributes[key] = value;
  }
  get(key) {
    return this.attributes[key];
  }
  async save() {
    if (!this.id) {
      idCounter += 1;
      this.id = `obj_${idCounter}`;
      store[this.className] = store[this.className] || {};
      store[this.className][this.id] = this;
    }
    return this;
  }
}

class FakeParseQuery {
  constructor(className) {
    this.className = className;
    this._order = [];
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
  limit() {
    return this;
  }
  include() {
    // No-op: fake objects always hold their full attributes (including any object set as a
    // pointer value), so there's no lazy-pointer behavior to simulate here.
    return this;
  }
  async find() {
    const all = Object.values(store[this.className] || {});
    return all.slice().sort((a, b) => {
      for (const field of this._order) {
        const av = a.get(field);
        const bv = b.get(field);
        if (av < bv) return -1;
        if (av > bv) return 1;
      }
      return 0;
    });
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
  }),
  Cloud: {
    define: (name, handler) => {
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
  const body = JSON.stringify({ choices: [{ message: { content: JSON.stringify(payload) } }] });
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
