const aiClient = require("./aiClient");
const prompts = require("./prompts");
const schemas = require("./schemas");

/**
 * Generates exactly 5 high-yield question/answer pairs for the pre-op Rapid Fire review.
 *
 * @param {{ caseDescription: string, prep?: object, previousQuestions?: string[] }} params
 * @param {{ generateJSON?: typeof aiClient.generateJSON }} [deps]
 */
async function generateRapidFire({ caseDescription, prep, previousQuestions }, deps = {}) {
  const generateJSON = deps.generateJSON || aiClient.generateJSON;
  const userPrompt = prompts.buildRapidFireUserPrompt({ caseDescription, prep, previousQuestions });

  const attempt = async (extraSystemNote) => {
    const raw = await generateJSON({
      systemPrompt: extraSystemNote
        ? `${prompts.RAPID_FIRE_SYSTEM_PROMPT}\n\n${extraSystemNote}`
        : prompts.RAPID_FIRE_SYSTEM_PROMPT,
      userPrompt,
      schemaName: "rapid_fire",
      schema: schemas.RAPID_FIRE_SCHEMA,
    });
    return schemas.validateRapidFire(raw);
  };

  try {
    return await attempt();
  } catch (firstError) {
    try {
      return await attempt("You must return exactly 5 question/answer pairs — no more, no fewer.");
    } catch (secondError) {
      const err = new Error("Failed to generate a valid Rapid Fire response.");
      err.cause = secondError;
      throw err;
    }
  }
}

module.exports = { generateRapidFire };
