const aiClient = require("./aiClient");
const prompts = require("./prompts");
const schemas = require("./schemas");

/**
 * Generates the structured OR Prep JSON for a case description.
 * Retries once with a stricter reformat instruction if the model output fails validation.
 *
 * @param {string} caseDescription
 * @param {{ generateJSON?: typeof aiClient.generateJSON }} [deps]
 */
async function generatePrep(caseDescription, deps = {}) {
  const generateJSON = deps.generateJSON || aiClient.generateJSON;
  const userPrompt = prompts.buildPrepUserPrompt(caseDescription);

  const attempt = async (extraSystemNote) => {
    const raw = await generateJSON({
      systemPrompt: extraSystemNote
        ? `${prompts.PREP_SYSTEM_PROMPT}\n\n${extraSystemNote}`
        : prompts.PREP_SYSTEM_PROMPT,
      userPrompt,
      schemaName: "or_prep",
      schema: schemas.PREP_JSON_SCHEMA,
    });
    return schemas.validatePrep(raw);
  };

  try {
    return await attempt();
  } catch (firstError) {
    try {
      return await attempt(
        "Your previous response did not match the required JSON shape. Respond again, strictly matching every required field."
      );
    } catch (secondError) {
      const err = new Error("Failed to generate a valid OR Prep response.");
      err.cause = secondError;
      throw err;
    }
  }
}

module.exports = { generatePrep };
