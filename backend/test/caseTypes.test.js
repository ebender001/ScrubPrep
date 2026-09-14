const { test } = require("node:test");
const assert = require("node:assert/strict");
const caseTypes = require("../cloud/scrubPrep/caseTypes");

function fakeObject(attrs) {
  return { get: (key) => attrs[key] };
}

test("listCaseTypes maps Parse objects to plain { name, specialty, featured }", async () => {
  const fetchCaseTypeObjects = async () => [
    fakeObject({ name: "Lap Chole", specialty: "general_surgery", sortOrder: 1, featured: true }),
    fakeObject({ name: "CABG", specialty: "cardiothoracic", sortOrder: 1, featured: false }),
  ];
  const result = await caseTypes.listCaseTypes({ fetchCaseTypeObjects });
  assert.deepEqual(result, [
    { name: "Lap Chole", specialty: "general_surgery", featured: true },
    { name: "CABG", specialty: "cardiothoracic", featured: false },
  ]);
});

test("listCaseTypes defaults featured to false when unset", async () => {
  const fetchCaseTypeObjects = async () => [fakeObject({ name: "Tonsillectomy", specialty: "ent" })];
  const result = await caseTypes.listCaseTypes({ fetchCaseTypeObjects });
  assert.equal(result[0].featured, false);
});

test("SPECIALTIES exposes the known specialty keys/labels", () => {
  const keys = caseTypes.SPECIALTIES.map((s) => s.key);
  assert.ok(keys.includes("general_surgery"));
  assert.ok(keys.includes("ent"));
  assert.ok(keys.includes("urology"));
  assert.ok(keys.includes("orthopedics"));
  assert.ok(keys.includes("cardiothoracic"));
});
