// USD price per 1M tokens, by model, for turning raw OpenAI token usage into an estimated
// cost. Pulled from OpenAI's published API pricing at the time this was written — OpenAI
// changes these from time to time, so treat this table as a snapshot: verify against
// https://openai.com/api/pricing/ before relying on totals for real financial decisions
// (e.g. setting a subscription price), and update the numbers here if they've drifted.
const MODEL_PRICING_USD_PER_1M_TOKENS = {
  "gpt-4.1": { input: 2.0, output: 8.0 },
  "gpt-4.1-mini": { input: 0.4, output: 1.6 },
  "gpt-4.1-nano": { input: 0.1, output: 0.4 },
  "gpt-4o": { input: 2.5, output: 10.0 },
  "gpt-4o-mini": { input: 0.15, output: 0.6 },
};

/**
 * @param {string} model
 * @param {{ prompt_tokens?: number, completion_tokens?: number }} usage - raw OpenAI usage object.
 * @returns {number|null} estimated cost in USD, or null if this model isn't in the pricing
 *   table (rather than silently reporting $0, which would understate real spend).
 */
function estimateCostUSD(model, usage) {
  const pricing = MODEL_PRICING_USD_PER_1M_TOKENS[model];
  if (!pricing || !usage) return null;
  const promptTokens = usage.prompt_tokens || 0;
  const completionTokens = usage.completion_tokens || 0;
  const cost = (promptTokens / 1e6) * pricing.input + (completionTokens / 1e6) * pricing.output;
  return Math.round(cost * 1e6) / 1e6;
}

module.exports = { MODEL_PRICING_USD_PER_1M_TOKENS, estimateCostUSD };
