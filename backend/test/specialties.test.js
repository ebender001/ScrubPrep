const { test } = require("node:test");
const assert = require("node:assert/strict");
const specialties = require("../cloud/scrubPrep/specialties");

function fakeSpecialty(id, name) {
  return { id, get: (key) => ({ name })[key] };
}

test("listSpecialties maps Parse objects to plain { id, name }", async () => {
  const fetchSpecialtyObjects = async () => [
    fakeSpecialty("sp1", "General Surgery"),
    fakeSpecialty("sp2", "Cardiac Surgery"),
  ];
  const result = await specialties.listSpecialties({ fetchSpecialtyObjects });
  assert.deepEqual(result, [
    { id: "sp1", name: "General Surgery" },
    { id: "sp2", name: "Cardiac Surgery" },
  ]);
});
