const { test } = require("node:test");
const assert = require("node:assert/strict");
const { generateRapidFire } = require("../cloud/scrubPrep/rapidFire");

function makeQA(n) {
  return Array.from({ length: n }, (_, i) => ({ question: `Q${i + 1}?`, answer: `A${i + 1}` }));
}

test("generateRapidFire returns exactly 5 questions", async () => {
  const generateJSON = async () => ({ questions: makeQA(5) });
  const result = await generateRapidFire({ caseDescription: "Appendectomy" }, { generateJSON });
  assert.equal(result.questions.length, 5);
});

test("generateRapidFire retries once if the wrong count is returned", async () => {
  let calls = 0;
  const generateJSON = async () => {
    calls += 1;
    return { questions: makeQA(calls === 1 ? 3 : 5) };
  };
  const result = await generateRapidFire({ caseDescription: "Appendectomy" }, { generateJSON });
  assert.equal(calls, 2);
  assert.equal(result.questions.length, 5);
});

test("generateRapidFire throws a clean error after repeated invalid output", async () => {
  const generateJSON = async () => ({ questions: makeQA(2) });
  await assert.rejects(
    () => generateRapidFire({ caseDescription: "Appendectomy" }, { generateJSON }),
    /Failed to generate a valid Rapid Fire response/
  );
});
