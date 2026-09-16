// Records one row per actual OpenAI API call (see cloud/main.js's withUsageTracking),
// so cost can be reported and broken down later (see scripts/report-ai-costs.js) — e.g.
// to estimate what a subscription needs to charge to cover AI spend per active user.
// Stored as its own `AIUsageEvent` Parse class, locked down the same way as ScrubCase/
// PimpMeSession (see scripts/setup-ai-usage-schema.js) — Master Key/Cloud Code only.
//
// Deliberately never throws: recording cost is purely observational and must never break
// or slow down the actual AI-backed feature it's measuring (same "decorative work can't
// break the primary flow" reasoning as elsewhere in this app).

const aiCost = require("./aiCost");

function newUsageEvent() {
  const AIUsageEventClass = Parse.Object.extend("AIUsageEvent");
  return new AIUsageEventClass();
}

/**
 * @param {{ functionName: string, model: string, usage: { prompt_tokens?: number, completion_tokens?: number, total_tokens?: number }, owner?: Parse.User|null }} params
 *   `owner` is the already-resolved `request.user` (or null/undefined for the AI-backed
 *   functions that don't require sign-in) — passed straight through as a pointer value,
 *   same as `cases.js`'s `owner` param, rather than re-derived from an id here.
 * @param {{ newUsageEvent?: typeof newUsageEvent }} [deps]
 */
async function recordUsage({ functionName, model, usage, owner }, deps = {}) {
  const createEvent = deps.newUsageEvent || newUsageEvent;
  try {
    const event = createEvent();
    event.set("functionName", functionName);
    event.set("model", model);
    event.set("promptTokens", (usage && usage.prompt_tokens) || 0);
    event.set("completionTokens", (usage && usage.completion_tokens) || 0);
    event.set("totalTokens", (usage && usage.total_tokens) || 0);
    event.set("estimatedCostUSD", aiCost.estimateCostUSD(model, usage));
    if (owner) {
      event.set("owner", owner);
    }
    await event.save(null, { useMasterKey: true });
  } catch (err) {
    console.error("Failed to record AI usage event:", err);
  }
}

module.exports = { recordUsage, newUsageEvent };
