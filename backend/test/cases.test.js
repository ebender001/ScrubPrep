const { test } = require("node:test");
const assert = require("node:assert/strict");
const cases = require("../cloud/scrubPrep/cases");

function fakeOwner(id) {
  return { id };
}

function fakeCaseObject(attrs) {
  const state = { ...attrs };
  return {
    id: state.id || "case1",
    createdAt: state.createdAt || new Date("2024-01-01T00:00:00Z"),
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

test("upsertCase creates a new case when none exists", async () => {
  const owner = fakeOwner("user1");
  const created = fakeCaseObject({});
  const result = await cases.upsertCase(
    { owner, caseDescription: "Lap chole", prep: { title: "Lap Chole" } },
    { fetchCaseObject: async () => null, newCaseObject: () => created }
  );
  assert.equal(result.caseDescription, "Lap chole");
  assert.deepEqual(result.prep, { title: "Lap Chole" });
  assert.equal(created.get("owner"), owner);
  assert.equal(created.get("normalizedDescription"), "lap chole");
  // A brand-new case was never reviewed, so lastReviewedAt should be left untouched (unset).
  assert.equal(created.get("lastReviewedAt"), undefined);
});

test("upsertCase updates and clears lastReviewedAt on an existing match instead of duplicating", async () => {
  const owner = fakeOwner("user1");
  const existing = fakeCaseObject({
    caseDescription: "Lap Chole",
    normalizedDescription: "lap chole",
    prep: { title: "Old" },
    lastReviewedAt: new Date("2024-01-01T00:00:00Z"),
  });
  const result = await cases.upsertCase(
    { owner, caseDescription: "Lap Chole", prep: { title: "New" } },
    { fetchCaseObject: async () => existing, newCaseObject: () => assert.fail("should not create a new object") }
  );
  assert.deepEqual(result.prep, { title: "New" });
  assert.equal(existing.get("lastReviewedAt"), null);
});

test("listCasesForOwner maps Parse objects to plain case objects", async () => {
  const owner = fakeOwner("user1");
  const obj = fakeCaseObject({ caseDescription: "CABG", prep: { title: "CABG" } });
  const result = await cases.listCasesForOwner(owner, { fetchCasesForOwner: async () => [obj] });
  assert.deepEqual(result, [
    {
      id: obj.id,
      caseDescription: "CABG",
      prep: { title: "CABG" },
      createdAt: obj.createdAt.toISOString(),
      updatedAt: obj.updatedAt.toISOString(),
      lastReviewedAt: null,
      specialty: null,
      notes: "",
    },
  ]);
});

test("listCasesForOwner includes the case's specialty id and name when set", async () => {
  const specialty = fakeCaseObject({ id: "sp1", name: "General Surgery" });
  const obj = fakeCaseObject({ caseDescription: "Lap chole", specialty });
  const [result] = await cases.listCasesForOwner(fakeOwner("user1"), { fetchCasesForOwner: async () => [obj] });
  assert.deepEqual(result.specialty, { id: "sp1", name: "General Surgery" });
});

test("upsertCase sets the specialty when provided and keeps the existing one when omitted", async () => {
  const owner = fakeOwner("user1");
  const specialty = fakeCaseObject({ id: "sp1", name: "General Surgery" });
  const created = fakeCaseObject({});
  const saved = await cases.upsertCase(
    { owner, caseDescription: "Lap chole", prep: {}, specialty },
    { fetchCaseObject: async () => null, newCaseObject: () => created }
  );
  assert.deepEqual(saved.specialty, { id: "sp1", name: "General Surgery" });

  const resaved = await cases.upsertCase(
    { owner, caseDescription: "Lap chole", prep: {} },
    { fetchCaseObject: async () => created, newCaseObject: () => assert.fail("should not create a new object") }
  );
  assert.deepEqual(resaved.specialty, { id: "sp1", name: "General Surgery" });
});

test("updateCaseNotes sets notes on the owned case, and returns null when not found/owned", async () => {
  const obj = fakeCaseObject({ caseDescription: "Lap chole" });
  const result = await cases.updateCaseNotes(
    { caseId: obj.id, owner: fakeOwner("user1"), notes: "Attending likes CVS called out" },
    { fetchOwnedCaseById: async () => obj }
  );
  assert.equal(result.notes, "Attending likes CVS called out");

  const missing = await cases.updateCaseNotes(
    { caseId: "nope", owner: fakeOwner("user1"), notes: "x" },
    { fetchOwnedCaseById: async () => null }
  );
  assert.equal(missing, null);
});

test("markCaseReviewed returns null when the case isn't found/owned", async () => {
  const result = await cases.markCaseReviewed(
    { caseId: "nope", owner: fakeOwner("user1") },
    { fetchOwnedCaseById: async () => null }
  );
  assert.equal(result, null);
});

test("markCaseReviewed sets lastReviewedAt on the owned case", async () => {
  const obj = fakeCaseObject({ caseDescription: "Lap Chole" });
  const result = await cases.markCaseReviewed(
    { caseId: obj.id, owner: fakeOwner("user1") },
    { fetchOwnedCaseById: async () => obj }
  );
  assert.equal(typeof result.lastReviewedAt, "string");
  assert.ok(!Number.isNaN(Date.parse(result.lastReviewedAt)));
});

test("deleteCase returns false when the case isn't found/owned, without cascading", async () => {
  let cascadeCalled = false;
  const result = await cases.deleteCase(
    { caseId: "nope", owner: fakeOwner("user1") },
    {
      fetchOwnedCaseById: async () => null,
      deleteSessionsForCase: async () => {
        cascadeCalled = true;
      },
    }
  );
  assert.equal(result, false);
  assert.equal(cascadeCalled, false);
});

test("deleteCase destroys the case and cascades to its Pimp Me sessions", async () => {
  const owner = fakeOwner("user1");
  const obj = fakeCaseObject({ normalizedDescription: "lap chole" });
  let cascadeArgs = null;
  const result = await cases.deleteCase(
    { caseId: obj.id, owner },
    {
      fetchOwnedCaseById: async () => obj,
      deleteSessionsForCase: async (args) => {
        cascadeArgs = args;
      },
    }
  );
  assert.equal(result, true);
  assert.equal(obj.destroyed, true);
  assert.deepEqual(cascadeArgs, { owner, normalizedDescription: "lap chole" });
});
