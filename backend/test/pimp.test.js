const { test } = require("node:test");
const assert = require("node:assert/strict");
const pimp = require("../cloud/scrubPrep/pimp");

test("getQuestionTarget returns expected counts per difficulty", () => {
  assert.equal(pimp.getQuestionTarget("easy"), 4);
  assert.equal(pimp.getQuestionTarget("typical"), 5);
  assert.equal(pimp.getQuestionTarget("tough"), 6);
  // unknown difficulty falls back to typical
  assert.equal(pimp.getQuestionTarget("nonsense"), 5);
});

test("isSessionComplete matches the difficulty's question target", () => {
  assert.equal(pimp.isSessionComplete(3, "easy"), false);
  assert.equal(pimp.isSessionComplete(4, "easy"), true);
  assert.equal(pimp.isSessionComplete(4, "typical"), false);
  assert.equal(pimp.isSessionComplete(5, "typical"), true);
  assert.equal(pimp.isSessionComplete(6, "tough"), true);
});

test("generateFirstQuestion validates and returns a question", async () => {
  const generateJSON = async () => ({ question: "What forms the hepatocystic triangle?" });
  const result = await pimp.generateFirstQuestion(
    { caseDescription: "Lap chole", difficulty: "typical" },
    { generateJSON }
  );
  assert.equal(result.question, "What forms the hepatocystic triangle?");
});

test("evaluateAnswer returns assessment, teaching point, and next question", async () => {
  const generateJSON = async () => ({
    assessment: "partially_correct",
    feedback: "You named two of three borders.",
    teaching_point: "The triangle is bounded by the cystic duct, common hepatic duct, and liver edge.",
    concept: "hepatocystic triangle",
    next_question: "What artery usually runs through this region?",
  });
  const result = await pimp.evaluateAnswer(
    {
      caseDescription: "Lap chole",
      difficulty: "typical",
      history: [],
      question: "What forms the hepatocystic triangle?",
      answer: "Cystic duct and common hepatic duct",
    },
    { generateJSON }
  );
  assert.equal(result.assessment, "partially_correct");
  assert.equal(result.next_question, "What artery usually runs through this region?");
});

test("evaluateFinalAnswer returns a readiness summary", async () => {
  const generateJSON = async () => ({
    assessment: "correct",
    feedback: "Correct.",
    teaching_point: "The cystic artery typically arises from the right hepatic artery.",
    concept: "cystic artery origin",
    strong: ["Indications for surgery", "Basic operative sequence"],
    review: ["Arterial anatomy variants"],
    two_minute_review: ["Cystic artery usually arises from the right hepatic artery."],
  });
  const result = await pimp.evaluateFinalAnswer(
    {
      caseDescription: "Lap chole",
      difficulty: "typical",
      history: [
        {
          question: "What forms the hepatocystic triangle?",
          answer: "Cystic duct and common hepatic duct",
          assessment: "partially_correct",
          concept: "hepatocystic triangle",
        },
      ],
      question: "Where does the cystic artery usually arise?",
      answer: "Right hepatic artery",
    },
    { generateJSON }
  );
  assert.equal(result.assessment, "correct");
  assert.deepEqual(result.strong, ["Indications for surgery", "Basic operative sequence"]);
  assert.deepEqual(result.two_minute_review, [
    "Cystic artery usually arises from the right hepatic artery.",
  ]);
});

test("evaluateAnswer rejects an invalid assessment value", async () => {
  const generateJSON = async () => ({
    assessment: "sort_of",
    feedback: "x",
    teaching_point: "x",
    concept: "x",
    next_question: "x",
  });
  await assert.rejects(() =>
    pimp.evaluateAnswer(
      { caseDescription: "Lap chole", difficulty: "typical", history: [], question: "Q", answer: "A" },
      { generateJSON }
    )
  );
});
