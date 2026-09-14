const { test } = require("node:test");
const assert = require("node:assert/strict");
const { generatePrep, UnrecognizedCaseError } = require("../cloud/scrubPrep/prep");

const VALID_PREP = {
  recognized: true,
  title: "Laparoscopic Cholecystectomy",
  case_summary: "A patient with symptomatic gallstones requiring elective cholecystectomy.",
  why_operating: ["Recurrent biliary colic", "Risk of complications if untreated"],
  anatomy: ["Cystic duct", "Cystic artery", "Common bile duct", "Hepatocystic triangle"],
  operation_overview: ["Establish pneumoperitoneum", "Achieve critical view of safety", "Clip and divide cystic duct/artery", "Remove gallbladder"],
  things_to_watch: ["Confirm critical view of safety before clipping"],
  complications: ["Bile duct injury", "Bleeding", "Bile leak"],
  must_know: ["Point 1", "Point 2", "Point 3", "Point 4", "Point 5"],
  likely_questions: [{ question: "What is the critical view of safety?", answer: "A method to confirm cystic duct/artery identity before dividing them." }],
};

test("generatePrep returns validated prep on first successful attempt", async () => {
  let calls = 0;
  const generateJSON = async () => {
    calls += 1;
    return VALID_PREP;
  };
  const result = await generatePrep("Lap chole for acute cholecystitis", { generateJSON });
  assert.equal(calls, 1);
  assert.equal(result.title, "Laparoscopic Cholecystectomy");
});

test("generatePrep retries once on malformed output then succeeds", async () => {
  let calls = 0;
  const generateJSON = async () => {
    calls += 1;
    if (calls === 1) return { title: "Missing fields" };
    return VALID_PREP;
  };
  const result = await generatePrep("Lap chole", { generateJSON });
  assert.equal(calls, 2);
  assert.equal(result.title, "Laparoscopic Cholecystectomy");
});

test("generatePrep throws a clean error after two failed attempts", async () => {
  const generateJSON = async () => ({ nope: true });
  await assert.rejects(
    () => generatePrep("Lap chole", { generateJSON }),
    /Failed to generate a valid OR Prep response/
  );
});

test("generatePrep throws UnrecognizedCaseError (no retry) when the model reports recognized: false", async () => {
  let calls = 0;
  const generateJSON = async () => {
    calls += 1;
    return { ...VALID_PREP, recognized: false, title: "Unrecognized Case" };
  };
  await assert.rejects(
    () => generatePrep("asdkjfhaslkdjf", { generateJSON }),
    (err) => err instanceof UnrecognizedCaseError
  );
  assert.equal(calls, 1, "should not retry a structurally valid recognized:false response");
});
