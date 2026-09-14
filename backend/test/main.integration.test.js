// Integration test for cloud/main.js using an in-memory fake Parse SDK and a
// stubbed https.request (so no real Parse Server or OpenAI call is made), to
// verify the Cloud Function wiring, PimpSession persistence, and the
// non-final vs. final answerPimpQuestion branches.

const { test } = require("node:test");
const assert = require("node:assert/strict");
const https = require("node:https");

let idCounter = 0;
const store = {};

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
  }
  async get(id) {
    const obj = (store[this.className] || {})[id];
    if (!obj) throw new FakeParseError(101, "not found");
    return obj;
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

test("generateRapidFire returns exactly 5 questions via the cloud function", async () => {
  responseQueue.push({
    questions: Array.from({ length: 5 }, (_, i) => ({ question: `Q${i}`, answer: `A${i}` })),
  });
  const result = await registry.generateRapidFire({
    params: { caseDescription: "Appendectomy", prep: { title: "Appendectomy" } },
  });
  assert.equal(result.questions.length, 5);
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
