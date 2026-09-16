const { test } = require("node:test");
const assert = require("node:assert/strict");
const { estimateCostUSD, MODEL_PRICING_USD_PER_1M_TOKENS } = require("../cloud/scrubPrep/aiCost");

test("estimateCostUSD computes cost from prompt + completion tokens for a known model", () => {
  const cost = estimateCostUSD("gpt-4.1", { prompt_tokens: 1000, completion_tokens: 500 });
  const pricing = MODEL_PRICING_USD_PER_1M_TOKENS["gpt-4.1"];
  const expected = (1000 / 1e6) * pricing.input + (500 / 1e6) * pricing.output;
  assert.equal(cost, Math.round(expected * 1e6) / 1e6);
  assert.ok(cost > 0);
});

test("estimateCostUSD returns null for a model with no pricing entry", () => {
  assert.equal(estimateCostUSD("some-future-model", { prompt_tokens: 100, completion_tokens: 100 }), null);
});

test("estimateCostUSD returns null when usage is missing", () => {
  assert.equal(estimateCostUSD("gpt-4.1", undefined), null);
});

test("estimateCostUSD treats missing token counts as zero rather than throwing", () => {
  assert.equal(estimateCostUSD("gpt-4.1", {}), 0);
});
