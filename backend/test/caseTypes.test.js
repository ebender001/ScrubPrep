const { test } = require("node:test");
const assert = require("node:assert/strict");
const caseTypes = require("../cloud/scrubPrep/caseTypes");

function fakeSpecialty(id, name, sortOrder) {
  const attrs = { name, sortOrder };
  return { id, get: (key) => attrs[key] };
}

function fakeCaseType(attrs) {
  return { get: (key) => attrs[key] };
}

test("listCaseTypes maps Parse objects to plain { name, fullName, specialty, featured }", async () => {
  const generalSurgery = fakeSpecialty("sp1", "General Surgery", 1);
  const fetchCaseTypeObjects = async () => [
    fakeCaseType({
      name: "Lap Chole",
      fullName: "Laparoscopic Cholecystectomy",
      specialty: generalSurgery,
      featured: true,
    }),
  ];
  const result = await caseTypes.listCaseTypes({ fetchCaseTypeObjects });
  assert.deepEqual(result, [
    {
      name: "Lap Chole",
      fullName: "Laparoscopic Cholecystectomy",
      specialty: { id: "sp1", name: "General Surgery" },
      featured: true,
    },
  ]);
});

test("listCaseTypes defaults featured to false when unset", async () => {
  const ent = fakeSpecialty("sp2", "ENT", 4);
  const fetchCaseTypeObjects = async () => [
    fakeCaseType({ name: "Tonsillectomy", fullName: "Tonsillectomy", specialty: ent }),
  ];
  const result = await caseTypes.listCaseTypes({ fetchCaseTypeObjects });
  assert.equal(result[0].featured, false);
});

test("listCaseTypes falls back to name when fullName is unset", async () => {
  const ent = fakeSpecialty("sp2", "ENT", 4);
  const fetchCaseTypeObjects = async () => [fakeCaseType({ name: "Tonsillectomy", specialty: ent })];
  const result = await caseTypes.listCaseTypes({ fetchCaseTypeObjects });
  assert.equal(result[0].fullName, "Tonsillectomy");
});

test("listCaseTypes returns null specialty for a row with no pointer set", async () => {
  const fetchCaseTypeObjects = async () => [fakeCaseType({ name: "Orphan Case", featured: false })];
  const result = await caseTypes.listCaseTypes({ fetchCaseTypeObjects });
  assert.equal(result[0].specialty, null);
});

test("listCaseTypes groups by specialty sortOrder, keeping query order within a specialty", async () => {
  const cardiac = fakeSpecialty("sp_cardiac", "Cardiac Surgery", 2);
  const generalSurgery = fakeSpecialty("sp_gs", "General Surgery", 1);
  const fetchCaseTypeObjects = async () => [
    // Query already returns rows ordered by each case type's own sortOrder/name.
    fakeCaseType({ name: "CABG", specialty: cardiac, featured: false }),
    fakeCaseType({ name: "Lap Chole", specialty: generalSurgery, featured: true }),
    fakeCaseType({ name: "Appendectomy", specialty: generalSurgery, featured: true }),
  ];
  const result = await caseTypes.listCaseTypes({ fetchCaseTypeObjects });
  assert.deepEqual(
    result.map((r) => r.name),
    ["Lap Chole", "Appendectomy", "CABG"]
  );
});
