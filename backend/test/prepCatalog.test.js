const { test } = require("node:test");
const assert = require("node:assert/strict");
const prepCatalog = require("../cloud/scrubPrep/prepCatalog");

function fakeCatalogObject(attrs) {
  const state = { ...attrs };
  return {
    id: state.id || "entry1",
    get: (key) => state[key],
    set: (key, value) => {
      state[key] = value;
    },
    save: async function () {
      return this;
    },
  };
}

test("normalizeDescription trims, lowercases, and collapses internal whitespace", () => {
  assert.equal(prepCatalog.normalizeDescription("  Lap   Chole  "), "lap chole");
  assert.equal(prepCatalog.normalizeDescription("Laparoscopic Cholecystectomy"), "laparoscopic cholecystectomy");
  assert.equal(prepCatalog.normalizeDescription(""), "");
});

test("getCachedPrep returns null on a miss", async () => {
  const result = await prepCatalog.getCachedPrep("appendectomy", {
    fetchCatalogObject: async () => null,
  });
  assert.equal(result, null);
});

test("getCachedPrep returns the cached prep on a current-version hit", async () => {
  const entry = fakeCatalogObject({ prep: { title: "Appendectomy" }, promptVersion: prepCatalog.PROMPT_VERSION });
  const result = await prepCatalog.getCachedPrep("appendectomy", {
    fetchCatalogObject: async () => entry,
  });
  assert.deepEqual(result, { title: "Appendectomy" });
});

test("getCachedPrep treats a stale prompt version as a miss", async () => {
  const entry = fakeCatalogObject({ prep: { title: "Old" }, promptVersion: prepCatalog.PROMPT_VERSION - 1 });
  const result = await prepCatalog.getCachedPrep("appendectomy", {
    fetchCatalogObject: async () => entry,
  });
  assert.equal(result, null);
});

test("upsertCatalogEntry creates a new entry when none exists", async () => {
  const created = fakeCatalogObject({});
  const entry = await prepCatalog.upsertCatalogEntry(
    { caseDescription: "Appendectomy", normalizedDescription: "appendectomy", prep: { title: "Appendectomy" } },
    { fetchCatalogObject: async () => null, newCatalogObject: () => created }
  );
  assert.equal(entry.get("caseDescription"), "Appendectomy");
  assert.equal(entry.get("normalizedDescription"), "appendectomy");
  assert.deepEqual(entry.get("prep"), { title: "Appendectomy" });
  assert.equal(entry.get("promptVersion"), prepCatalog.PROMPT_VERSION);
});

test("upsertCatalogEntry overwrites an existing entry in place instead of duplicating", async () => {
  const existing = fakeCatalogObject({
    caseDescription: "Appendectomy",
    normalizedDescription: "appendectomy",
    prep: { title: "Old" },
    promptVersion: prepCatalog.PROMPT_VERSION - 1,
  });
  const entry = await prepCatalog.upsertCatalogEntry(
    { caseDescription: "Appendectomy", normalizedDescription: "appendectomy", prep: { title: "New" } },
    { fetchCatalogObject: async () => existing, newCatalogObject: () => assert.fail("should not create a new object") }
  );
  assert.deepEqual(entry.get("prep"), { title: "New" });
  assert.equal(entry.get("promptVersion"), prepCatalog.PROMPT_VERSION);
});
