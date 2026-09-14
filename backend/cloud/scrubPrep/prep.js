const aiClient = require("./aiClient");
const prompts = require("./prompts");
const schemas = require("./schemas");

/** Thrown when the model itself reports the case description isn't a real procedure
 * (schemas.PREP_JSON_SCHEMA's `recognized: false`) — distinct from a malformed/invalid
 * response, so main.js can surface a friendly (and specifically *not* generic) error
 * instead of retrying or returning a prep full of placeholder content.
 */
class UnrecognizedCaseError extends Error {
  constructor(message) {
    super(message);
    this.name = "UnrecognizedCaseError";
  }
}

/**
 * Generates the structured OR Prep JSON for a case description.
 * Retries once with a stricter reformat instruction if the model output fails validation.
 * Throws UnrecognizedCaseError (no retry) if the model reports the description isn't a
 * real procedure — retrying gibberish with the same prompt won't make it a real one.
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

  let result;
  try {
    result = await attempt();
  } catch (firstError) {
    try {
      result = await attempt(
        "Your previous response did not match the required JSON shape. Respond again, strictly matching every required field."
      );
    } catch (secondError) {
      const err = new Error("Failed to generate a valid OR Prep response.");
      err.cause = secondError;
      throw err;
    }
  }

  if (!result.recognized) {
    throw new UnrecognizedCaseError(`"${caseDescription}" wasn't recognized as a real procedure.`);
  }
  return result;
}

module.exports = { generatePrep, UnrecognizedCaseError };
