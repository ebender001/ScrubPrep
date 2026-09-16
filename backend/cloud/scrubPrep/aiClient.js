// Thin wrapper around the OpenAI Chat Completions API using Structured Outputs
// (response_format: json_schema, strict). Uses Node's core `https` module rather
// than the global `fetch` or the `openai` npm package, since Back4App's classic
// Cloud Code sandbox may run an older Node runtime that lacks a global fetch.

const https = require("https");

const OPENAI_HOST = "api.openai.com";
const OPENAI_PATH = "/v1/chat/completions";

class AIClientError extends Error {
  constructor(message, options) {
    super(message);
    this.name = "AIClientError";
    if (options && options.cause) {
      this.cause = options.cause;
    }
  }
}

function postJSON(host, path, headers, body) {
  return new Promise(function (resolve, reject) {
    const payload = JSON.stringify(body);
    const requestHeaders = Object.assign(
      {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(payload),
      },
      headers
    );
    const req = https.request(
      { host: host, path: path, method: "POST", headers: requestHeaders },
      function (res) {
        let data = "";
        res.on("data", function (chunk) {
          data += chunk;
        });
        res.on("end", function () {
          resolve({ statusCode: res.statusCode, body: data });
        });
      }
    );
    req.on("error", function (err) {
      reject(err);
    });
    req.write(payload);
    req.end();
  });
}

/**
 * @param {object} params
 * @param {string} params.systemPrompt
 * @param {string} params.userPrompt
 * @param {string} params.schemaName
 * @param {object} params.schema - JSON schema (strict-compatible) for the expected response.
 * @param {number} [params.temperature]
 * @param {typeof postJSON} [params.requestImpl] - injectable for tests.
 * @param {(usage: {prompt_tokens: number, completion_tokens: number, total_tokens: number}, model: string) => (void|Promise<void>)} [params.onUsage] -
 *   called with OpenAI's token usage for this call, once the response is parsed, so a
 *   caller (see cloud/main.js's withUsageTracking) can record cost per Cloud Function
 *   call without every module along the way (prep.js, pimp.js, rapidFire.js) needing to
 *   know anything about cost tracking. Never allowed to fail the actual AI call — errors
 *   from it are swallowed, same "decorative work must never break the primary flow"
 *   reasoning used throughout this app.
 * @returns {Promise<object>} parsed JSON response body
 */
async function generateJSON(params) {
  const systemPrompt = params.systemPrompt;
  const userPrompt = params.userPrompt;
  const schemaName = params.schemaName;
  const schema = params.schema;
  const temperature = typeof params.temperature === "number" ? params.temperature : 0.3;
  const requestFn = params.requestImpl || postJSON;
  const onUsage = params.onUsage;

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new AIClientError("OPENAI_API_KEY is not configured.");
  }
  const model = process.env.OPENAI_MODEL || "gpt-4.1";

  let response;
  try {
    response = await requestFn(
      OPENAI_HOST,
      OPENAI_PATH,
      { Authorization: "Bearer " + apiKey },
      {
        model: model,
        temperature: temperature,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        response_format: {
          type: "json_schema",
          json_schema: {
            name: schemaName,
            strict: true,
            schema: schema,
          },
        },
      }
    );
  } catch (err) {
    throw new AIClientError("Failed to reach OpenAI.", { cause: err });
  }

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw new AIClientError(
      "OpenAI request failed with status " + response.statusCode + ": " + response.body
    );
  }

  let parsedBody;
  try {
    parsedBody = JSON.parse(response.body);
  } catch (err) {
    throw new AIClientError("OpenAI response was not valid JSON.", { cause: err });
  }

  if (onUsage && parsedBody.usage) {
    try {
      await onUsage(parsedBody.usage, model);
    } catch (err) {
      console.error("aiClient onUsage callback failed:", err);
    }
  }

  const choices = parsedBody.choices;
  const firstChoice = choices && choices[0];
  const message = firstChoice && firstChoice.message;
  const content = message && message.content;
  if (typeof content !== "string") {
    throw new AIClientError("OpenAI response did not contain message content.");
  }

  try {
    return JSON.parse(content);
  } catch (err) {
    throw new AIClientError("OpenAI response content was not valid JSON.", { cause: err });
  }
}

module.exports = { generateJSON: generateJSON, AIClientError: AIClientError };
