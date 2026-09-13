// Thin wrapper around the OpenAI Chat Completions API using Structured Outputs
// (response_format: json_schema, strict). No `openai` npm dependency — Back4App's
// Node 18+ Cloud Code runtime provides a global `fetch`.

const OPENAI_URL = "https://api.openai.com/v1/chat/completions";

class AIClientError extends Error {
  constructor(message, { cause } = {}) {
    super(message);
    this.name = "AIClientError";
    if (cause) this.cause = cause;
  }
}

/**
 * @param {object} params
 * @param {string} params.systemPrompt
 * @param {string} params.userPrompt
 * @param {string} params.schemaName
 * @param {object} params.schema - JSON schema (strict-compatible) for the expected response.
 * @param {number} [params.temperature]
 * @param {typeof fetch} [params.fetchImpl] - injectable for tests.
 * @returns {Promise<object>} parsed JSON response body
 */
async function generateJSON({
  systemPrompt,
  userPrompt,
  schemaName,
  schema,
  temperature = 0.3,
  fetchImpl = fetch,
}) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new AIClientError("OPENAI_API_KEY is not configured.");
  }
  const model = process.env.OPENAI_MODEL || "gpt-4.1";

  let response;
  try {
    response = await fetchImpl(OPENAI_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        temperature,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        response_format: {
          type: "json_schema",
          json_schema: {
            name: schemaName,
            strict: true,
            schema,
          },
        },
      }),
    });
  } catch (err) {
    throw new AIClientError("Failed to reach OpenAI.", { cause: err });
  }

  if (!response.ok) {
    let detail = "";
    try {
      detail = await response.text();
    } catch {
      // ignore
    }
    throw new AIClientError(`OpenAI request failed with status ${response.status}: ${detail}`);
  }

  let body;
  try {
    body = await response.json();
  } catch (err) {
    throw new AIClientError("OpenAI response was not valid JSON.", { cause: err });
  }

  const content = body?.choices?.[0]?.message?.content;
  if (typeof content !== "string") {
    throw new AIClientError("OpenAI response did not contain message content.");
  }

  try {
    return JSON.parse(content);
  } catch (err) {
    throw new AIClientError("OpenAI response content was not valid JSON.", { cause: err });
  }
}

module.exports = { generateJSON, AIClientError };
