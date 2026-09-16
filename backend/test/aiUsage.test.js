const { test } = require("node:test");
const assert = require("node:assert/strict");
const { recordUsage } = require("../cloud/scrubPrep/aiUsage");

function fakeUsageEvent() {
  const state = {};
  return {
    set: (key, value) => {
      state[key] = value;
    },
    get: (key) => state[key],
    save: async function () {
      return this;
    },
    _state: state,
  };
}

test("recordUsage stores token counts and estimated cost for a known model", async () => {
  const event = fakeUsageEvent();
  await recordUsage(
    {
      functionName: "generateScrubPrep",
      model: "gpt-4.1",
      usage: { prompt_tokens: 1000, completion_tokens: 500, total_tokens: 1500 },
      owner: null,
    },
    { newUsageEvent: () => event }
  );
  assert.equal(event._state.functionName, "generateScrubPrep");
  assert.equal(event._state.model, "gpt-4.1");
  assert.equal(event._state.promptTokens, 1000);
  assert.equal(event._state.completionTokens, 500);
  assert.equal(event._state.totalTokens, 1500);
  assert.ok(typeof event._state.estimatedCostUSD === "number" && event._state.estimatedCostUSD > 0);
  assert.equal(event._state.owner, undefined);
});

test("recordUsage attaches owner when provided", async () => {
  const event = fakeUsageEvent();
  const owner = { id: "user_1" };
  await recordUsage(
    { functionName: "generateRapidFire", model: "gpt-4.1", usage: { prompt_tokens: 10, completion_tokens: 10 }, owner },
    { newUsageEvent: () => event }
  );
  assert.equal(event._state.owner, owner);
});

test("recordUsage swallows errors instead of throwing (must never break the AI call it's measuring)", async () => {
  const event = {
    set: () => {
      throw new Error("boom");
    },
  };
  await assert.doesNotReject(() =>
    recordUsage(
      { functionName: "generateScrubPrep", model: "gpt-4.1", usage: { prompt_tokens: 1, completion_tokens: 1 } },
      { newUsageEvent: () => event }
    )
  );
});
