const { test } = require("node:test");
const assert = require("node:assert/strict");
const pimpMeSessions = require("../cloud/scrubPrep/pimpMeSessions");

function fakeOwner(id) {
  return { id };
}

function fakeSessionObject(attrs) {
  const state = { ...attrs };
  return {
    id: state.id || "session1",
    updatedAt: state.updatedAt || new Date("2024-01-02T00:00:00Z"),
    get: (key) => state[key],
    set: (key, value) => {
      state[key] = value;
    },
    save: async function () {
      return this;
    },
    destroy: async function () {
      this.destroyed = true;
    },
  };
}

test("upsertSession creates a new session when none exists for this (case, difficulty)", async () => {
  const owner = fakeOwner("user1");
  const created = fakeSessionObject({});
  const result = await pimpMeSessions.upsertSession(
    {
      owner,
      caseDescription: "Lap chole",
      difficulty: "typical",
      transcript: [{ question: "Q", answer: "A", assessment: "correct" }],
      summary: { strong: ["x"], review: [], twoMinuteReview: [] },
    },
    { fetchSessionObject: async () => null, newSessionObject: () => created }
  );
  assert.equal(result.difficulty, "typical");
  assert.equal(created.get("normalizedDescription"), "lap chole");
  assert.equal(created.get("owner"), owner);
  assert.ok(created.get("completedAt") instanceof Date);
});

test("upsertSession overwrites the existing row for the same (owner, case, difficulty) instead of duplicating", async () => {
  const owner = fakeOwner("user1");
  const existing = fakeSessionObject({
    caseDescription: "Lap Chole",
    normalizedDescription: "lap chole",
    difficulty: "easy",
    transcript: [{ question: "old", answer: "old", assessment: "incorrect" }],
  });
  const result = await pimpMeSessions.upsertSession(
    {
      owner,
      caseDescription: "Lap Chole",
      difficulty: "easy",
      transcript: [{ question: "new", answer: "new", assessment: "correct" }],
      summary: { strong: [], review: [], twoMinuteReview: [] },
    },
    { fetchSessionObject: async () => existing, newSessionObject: () => assert.fail("should not create a new object") }
  );
  assert.deepEqual(result.transcript, [{ question: "new", answer: "new", assessment: "correct" }]);
});

test("listSessionsForCase maps Parse objects to plain session objects", async () => {
  const owner = fakeOwner("user1");
  const obj = fakeSessionObject({
    caseDescription: "Lap Chole",
    difficulty: "tough",
    transcript: [],
    summary: { strong: [], review: [], twoMinuteReview: [] },
    completedAt: new Date("2024-01-03T00:00:00Z"),
  });
  const result = await pimpMeSessions.listSessionsForCase(
    { owner, caseDescription: "Lap Chole" },
    { fetchSessionsForCase: async () => [obj] }
  );
  assert.deepEqual(result, [
    {
      id: obj.id,
      caseDescription: "Lap Chole",
      difficulty: "tough",
      transcript: [],
      summary: { strong: [], review: [], twoMinuteReview: [] },
      completedAt: obj.get("completedAt").toISOString(),
    },
  ]);
});

test("deleteSessionsForCase destroys every matching session", async () => {
  const owner = fakeOwner("user1");
  const a = fakeSessionObject({ id: "a" });
  const b = fakeSessionObject({ id: "b" });
  await pimpMeSessions.deleteSessionsForCase(
    { owner, normalizedDescription: "lap chole" },
    { fetchSessionsForCase: async () => [a, b] }
  );
  assert.equal(a.destroyed, true);
  assert.equal(b.destroyed, true);
});
