const { test } = require("node:test");
const assert = require("node:assert/strict");
const schemas = require("../cloud/scrubPrep/schemas");

test("containsLikelyPHI flags obvious identifiers", () => {
  assert.equal(schemas.containsLikelyPHI("Lap chole for MRN 12345"), true);
  assert.equal(schemas.containsLikelyPHI("Patient DOB 1/1/1980, chole"), true);
  assert.equal(schemas.containsLikelyPHI("SSN 123-45-6789"), true);
  assert.equal(schemas.containsLikelyPHI("Patient name: John Smith"), true);
});

test("containsLikelyPHI does not flag ordinary case descriptions", () => {
  assert.equal(schemas.containsLikelyPHI("Laparoscopic cholecystectomy for acute cholecystitis"), false);
  assert.equal(schemas.containsLikelyPHI("Right colectomy for ascending colon cancer"), false);
});

test("validatePrep rejects missing required fields", () => {
  assert.throws(() => schemas.validatePrep({ title: "x" }));
});

test("validateRapidFire enforces exactly 5 items", () => {
  const four = { questions: Array.from({ length: 4 }, (_, i) => ({ question: `Q${i}`, answer: `A${i}` })) };
  const five = { questions: Array.from({ length: 5 }, (_, i) => ({ question: `Q${i}`, answer: `A${i}` })) };
  assert.throws(() => schemas.validateRapidFire(four));
  assert.doesNotThrow(() => schemas.validateRapidFire(five));
});
