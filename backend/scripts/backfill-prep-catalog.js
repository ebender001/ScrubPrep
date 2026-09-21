#!/usr/bin/env node
// One-time (or periodically re-run) job: pre-populates PrepCatalog with every case type
// fullName from the live CaseType catalog, so every Home-screen chip request is a cache
// hit from the start instead of everyone's first tap paying for a fresh OpenAI call.
// Safe to re-run: skips any case type that already has a current-PROMPT_VERSION catalog
// entry (see cloud/scrubPrep/prepCatalog.js).
//
// Makes REAL OpenAI calls (billed) for every case type not yet cached. At last measurement
// (see scripts/report-ai-costs.js) generateScrubPrep averaged ~$0.007/call, so populating
// the full ~85-entry catalog from scratch costs roughly $0.60.
//
// Usage (reads backend/.env for PARSE_APP_ID/PARSE_MASTER_KEY and OPENAI_API_KEY if present):
//   node scripts/backfill-prep-catalog.js

const { loadContext, restRequest } = require("./lib/parseRest");
const { generatePrep, UnrecognizedCaseError } = require("../cloud/scrubPrep/prep");
const { generateJSON } = require("../cloud/scrubPrep/aiClient");
const { normalizeDescription, PROMPT_VERSION } = require("../cloud/scrubPrep/prepCatalog");
const { estimateCostUSD } = require("../cloud/scrubPrep/aiCost");

async function fetchCaseTypeFullNames(ctx) {
  const res = await restRequest({ method: "GET", pathname: "classes/CaseType?limit=500", ...ctx });
  const names = (res.results || []).map((r) => r.fullName || r.name).filter(Boolean);
  return Array.from(new Set(names)); // dedupe: distinct chips can share a fullName
}

async function fetchExistingCatalogEntry(ctx, normalizedDescription) {
  const where = encodeURIComponent(JSON.stringify({ normalizedDescription }));
  const res = await restRequest({
    method: "GET",
    pathname: `classes/PrepCatalog?limit=1&where=${where}`,
    ...ctx,
  });
  return (res.results || [])[0] || null;
}

async function insertCatalogEntry(ctx, { caseDescription, normalizedDescription, prep }) {
  return restRequest({
    method: "POST",
    pathname: "classes/PrepCatalog",
    body: { caseDescription, normalizedDescription, prep, promptVersion: PROMPT_VERSION },
    ...ctx,
  });
}

async function logUsageEvent(ctx, { model, usage }) {
  try {
    await restRequest({
      method: "POST",
      pathname: "classes/AIUsageEvent",
      // Tagged distinctly from "generateScrubPrep" (the live Cloud Function) so
      // scripts/report-ai-costs.js can show backfill spend as its own line rather than
      // blending it into organic user-driven usage.
      body: {
        functionName: "generateScrubPrep:backfill",
        model,
        promptTokens: (usage && usage.prompt_tokens) || 0,
        completionTokens: (usage && usage.completion_tokens) || 0,
        totalTokens: (usage && usage.total_tokens) || 0,
        estimatedCostUSD: estimateCostUSD(model, usage),
      },
      ...ctx,
    });
  } catch (err) {
    console.error("  (failed to log AIUsageEvent:", err.message, ")");
  }
}

async function generateWithUsage(caseDescription) {
  const usageEvents = [];
  const wrappedGenerateJSON = (params) =>
    generateJSON(
      Object.assign({}, params, {
        onUsage: (usage, model) => usageEvents.push({ usage, model }),
      })
    );
  const result = await generatePrep(caseDescription, { generateJSON: wrappedGenerateJSON });
  return { result, usageEvents };
}

async function main() {
  const ctx = loadContext();
  if (!process.env.OPENAI_API_KEY) {
    console.error("Set OPENAI_API_KEY in your environment (or backend/.env) before running this.");
    process.exit(1);
  }

  const fullNames = await fetchCaseTypeFullNames(ctx);
  console.log(`Found ${fullNames.length} distinct case type(s) in the catalog.\n`);

  let generated = 0;
  let skipped = 0;
  let failed = 0;
  let totalCost = 0;

  for (const caseDescription of fullNames) {
    const normalizedDescription = normalizeDescription(caseDescription);
    const existing = await fetchExistingCatalogEntry(ctx, normalizedDescription);
    if (existing && existing.promptVersion === PROMPT_VERSION) {
      console.log(`SKIP  (already cached): ${caseDescription}`);
      skipped++;
      continue;
    }

    let usageEvents = [];
    try {
      const generated_ = await generateWithUsage(caseDescription);
      usageEvents = generated_.usageEvents;
      await insertCatalogEntry(ctx, { caseDescription, normalizedDescription, prep: generated_.result });

      let callCost = 0;
      for (const { usage, model } of usageEvents) {
        callCost += estimateCostUSD(model, usage) || 0;
        await logUsageEvent(ctx, { model, usage });
      }
      totalCost += callCost;
      const extra = usageEvents.length > 1 ? `, ${usageEvents.length} calls (retried)` : "";
      console.log(`OK    ($${callCost.toFixed(5)}${extra}): ${caseDescription}`);
      generated++;
    } catch (err) {
      // Even a failed attempt may have consumed real tokens (e.g. a malformed first
      // attempt before the retry also fails) — still log and count that spend.
      let callCost = 0;
      for (const { usage, model } of usageEvents) {
        callCost += estimateCostUSD(model, usage) || 0;
        await logUsageEvent(ctx, { model, usage });
      }
      totalCost += callCost;

      if (err instanceof UnrecognizedCaseError) {
        console.log(`FAIL  (not recognized by the model, $${callCost.toFixed(5)}): ${caseDescription}`);
      } else {
        console.log(`FAIL  (${err.message}, $${callCost.toFixed(5)}): ${caseDescription}`);
      }
      failed++;
    }
  }

  console.log("");
  console.log(`Generated: ${generated}, skipped (already cached): ${skipped}, failed: ${failed}`);
  console.log(`Estimated spend this run: $${totalCost.toFixed(4)}`);
}

main().catch((err) => {
  console.error("Backfill failed:", err.message);
  process.exit(1);
});
