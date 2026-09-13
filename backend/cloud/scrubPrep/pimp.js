const aiClient = require("./aiClient");
const prompts = require("./prompts");
const schemas = require("./schemas");

// Deliberately Parse-free: Cloud Code (main.js) owns PimpSession persistence and
// calls these pure functions, which keeps this module unit-testable without a
// running Parse Server.

function getQuestionTarget(difficulty) {
  const key = prompts.normalizeDifficulty(difficulty);
  return prompts.DIFFICULTY_QUESTION_TARGET[key];
}

/**
 * @param {{ caseDescription: string, prep?: object, difficulty?: string }} params
 * @param {{ generateJSON?: typeof aiClient.generateJSON }} [deps]
 * @returns {Promise<{ question: string }>}
 */
async function generateFirstQuestion({ caseDescription, prep, difficulty }, deps = {}) {
  const generateJSON = deps.generateJSON || aiClient.generateJSON;
  const raw = await generateJSON({
    systemPrompt: prompts.PIMP_SYSTEM_PROMPT,
    userPrompt: prompts.buildPimpFirstQuestionUserPrompt({ caseDescription, prep, difficulty }),
    schemaName: "pimp_first_question",
    schema: schemas.PIMP_FIRST_QUESTION_SCHEMA,
  });
  return schemas.validatePimpFirstQuestion(raw);
}

/**
 * Evaluates an answer that is NOT the last question of the session.
 *
 * @param {{ caseDescription: string, prep?: object, difficulty?: string, history: Array, question: string, answer: string }} params
 * @param {{ generateJSON?: typeof aiClient.generateJSON }} [deps]
 */
async function evaluateAnswer(
  { caseDescription, prep, difficulty, history, question, answer },
  deps = {}
) {
  const generateJSON = deps.generateJSON || aiClient.generateJSON;
  const raw = await generateJSON({
    systemPrompt: prompts.PIMP_SYSTEM_PROMPT,
    userPrompt: prompts.buildPimpEvalUserPrompt({
      caseDescription,
      prep,
      difficulty,
      history,
      question,
      answer,
    }),
    schemaName: "pimp_eval",
    schema: schemas.PIMP_EVAL_SCHEMA,
  });
  return schemas.validatePimpEval(raw);
}

/**
 * Evaluates the LAST answer of the session and produces the readiness summary.
 *
 * @param {{ caseDescription: string, prep?: object, difficulty?: string, history: Array, question: string, answer: string }} params
 * @param {{ generateJSON?: typeof aiClient.generateJSON }} [deps]
 */
async function evaluateFinalAnswer(
  { caseDescription, prep, difficulty, history, question, answer },
  deps = {}
) {
  const generateJSON = deps.generateJSON || aiClient.generateJSON;
  const raw = await generateJSON({
    systemPrompt: prompts.PIMP_SYSTEM_PROMPT,
    userPrompt: prompts.buildPimpFinalEvalUserPrompt({
      caseDescription,
      prep,
      difficulty,
      history,
      question,
      answer,
    }),
    schemaName: "pimp_final_eval",
    schema: schemas.PIMP_FINAL_EVAL_SCHEMA,
  });
  return schemas.validatePimpFinalEval(raw);
}

function isSessionComplete(historyLengthAfterThisTurn, difficulty) {
  return historyLengthAfterThisTurn >= getQuestionTarget(difficulty);
}

module.exports = {
  getQuestionTarget,
  generateFirstQuestion,
  evaluateAnswer,
  evaluateFinalAnswer,
  isSessionComplete,
};
