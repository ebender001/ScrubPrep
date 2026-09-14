const { test } = require("node:test");
const assert = require("node:assert/strict");
const specialties = require("../cloud/scrubPrep/specialties");

function fakeSpecialty(id, attrs) {
  return { id, get: (key) => attrs[key] };
}

test("listSpecialties maps Parse objects to plain { id, name, exampleCaseDescription }", async () => {
  const fetchSpecialtyObjects = async () => [
    fakeSpecialty("sp1", { name: "General Surgery", exampleCaseDescription: "Lap chole for acute cholecystitis" }),
    fakeSpecialty("sp2", { name: "Cardiac Surgery", exampleCaseDescription: "CABG \u{00D7}3 for multivessel CAD" }),
  ];
  const result = await specialties.listSpecialties({ fetchSpecialtyObjects });
  assert.deepEqual(result, [
    { id: "sp1", name: "General Surgery", exampleCaseDescription: "Lap chole for acute cholecystitis" },
    { id: "sp2", name: "Cardiac Surgery", exampleCaseDescription: "CABG \u{00D7}3 for multivessel CAD" },
  ]);
});

test("listSpecialties defaults exampleCaseDescription to an empty string when unset", async () => {
  const fetchSpecialtyObjects = async () => [fakeSpecialty("sp3", { name: "ENT" })];
  const result = await specialties.listSpecialties({ fetchSpecialtyObjects });
  assert.equal(result[0].exampleCaseDescription, "");
});
