#!/usr/bin/env node
// Reports estimated OpenAI API spend recorded in the AIUsageEvent Parse class (one row
// per actual OpenAI API call — see cloud/scrubPrep/aiUsage.js) so real cost can be checked
// directly, e.g. to figure out what a subscription needs to charge per user to cover AI
// spend. Cost estimates depend on cloud/scrubPrep/aiCost.js's pricing table being current —
// see the comment there.
//
// Usage (reads backend/.env if present):
//   node scripts/report-ai-costs.js            # all-time
//   node scripts/report-ai-costs.js --days 30  # last 30 days only

const { loadContext, restRequest } = require("./lib/parseRest");

const PAGE_SIZE = 1000;
const MAX_PAGES = 50; // safety cap: 50,000 rows per run

function parseArgs(argv) {
  const args = { days: null };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--days") {
      args.days = Number(argv[i + 1]);
      i++;
    }
  }
  return args;
}

async function fetchAllEvents(ctx, days) {
  const where = {};
  if (days) {
    const cutoff = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
    where.createdAt = { $gte: { __type: "Date", iso: cutoff.toISOString() } };
  }
  const whereParam = encodeURIComponent(JSON.stringify(where));

  const events = [];
  let skip = 0;
  for (let page = 0; page < MAX_PAGES; page++) {
    const pathname = `classes/AIUsageEvent?limit=${PAGE_SIZE}&skip=${skip}&order=createdAt&where=${whereParam}`;
    const response = await restRequest({ method: "GET", pathname, ...ctx });
    const results = response.results || [];
    events.push(...results);
    if (results.length < PAGE_SIZE) break;
    skip += PAGE_SIZE;
  }
  return events;
}

function usd(n) {
  return "$" + n.toFixed(2);
}

function summarize(events) {
  const totals = { totalCost: 0, unknownPricingCount: 0, totalTokens: 0, promptTokens: 0, completionTokens: 0 };
  const byFunction = {};
  const byModel = {};
  const owners = new Set();

  for (const e of events) {
    const cost = typeof e.estimatedCostUSD === "number" ? e.estimatedCostUSD : null;
    if (cost === null) totals.unknownPricingCount++;
    else totals.totalCost += cost;
    totals.totalTokens += e.totalTokens || 0;
    totals.promptTokens += e.promptTokens || 0;
    totals.completionTokens += e.completionTokens || 0;
    if (e.owner && e.owner.objectId) owners.add(e.owner.objectId);

    const fnName = e.functionName || "(unknown)";
    const fnBucket = (byFunction[fnName] = byFunction[fnName] || { count: 0, cost: 0, tokens: 0 });
    fnBucket.count += 1;
    fnBucket.cost += cost || 0;
    fnBucket.tokens += e.totalTokens || 0;

    const modelName = e.model || "(unknown)";
    const modelBucket = (byModel[modelName] = byModel[modelName] || { count: 0, cost: 0, tokens: 0 });
    modelBucket.count += 1;
    modelBucket.cost += cost || 0;
    modelBucket.tokens += e.totalTokens || 0;
  }

  return { totals, byFunction, byModel, distinctUsers: owners.size, callCount: events.length };
}

function printBucketTable(buckets) {
  const sorted = Object.entries(buckets).sort((a, b) => b[1].cost - a[1].cost);
  for (const [name, bucket] of sorted) {
    const avg = bucket.count ? bucket.cost / bucket.count : 0;
    console.log(
      `  ${name.padEnd(22)} calls=${String(bucket.count).padEnd(7)} cost=${usd(bucket.cost).padEnd(11)} avg/call=${usd(avg)}`
    );
  }
}

function printReport({ totals, byFunction, byModel, distinctUsers, callCount }, events, days) {
  console.log("");
  console.log(days ? `AI cost report -- last ${days} day(s)` : "AI cost report -- all time");
  console.log("=".repeat(60));
  console.log(`Total API calls:          ${callCount}`);
  console.log(`Distinct signed-in users: ${distinctUsers}`);
  console.log(
    `Total tokens:             ${totals.totalTokens.toLocaleString()} ` +
      `(${totals.promptTokens.toLocaleString()} prompt / ${totals.completionTokens.toLocaleString()} completion)`
  );
  console.log(`Estimated total cost:     ${usd(totals.totalCost)}`);
  if (totals.unknownPricingCount > 0) {
    console.log(
      `  Note: ${totals.unknownPricingCount} call(s) used a model with no entry in aiCost.js's ` +
        `pricing table -- excluded from the total above. Add that model's pricing there for an accurate total.`
    );
  }
  if (distinctUsers > 0) {
    console.log(`Avg. cost per signed-in user: ${usd(totals.totalCost / distinctUsers)}`);
  }

  console.log("");
  console.log("By Cloud Function:");
  printBucketTable(byFunction);

  console.log("");
  console.log("By model:");
  printBucketTable(byModel);

  if (events.length > 1) {
    const first = new Date(events[0].createdAt);
    const last = new Date(events[events.length - 1].createdAt);
    const spanDays = Math.max(1, (last - first) / (24 * 60 * 60 * 1000));
    const perDay = totals.totalCost / spanDays;
    console.log("");
    console.log(
      `Date range covered: ${first.toISOString().slice(0, 10)} to ${last.toISOString().slice(0, 10)} ` +
        `(${spanDays.toFixed(1)} day(s))`
    );
    console.log(`Avg. cost/day:              ${usd(perDay)}`);
    console.log(`Projected cost/month (30d): ${usd(perDay * 30)}`);
  }
  console.log("");
}

async function main() {
  const ctx = loadContext();
  const { days } = parseArgs(process.argv.slice(2));
  const events = await fetchAllEvents(ctx, days);
  if (events.length === 0) {
    console.log(
      "No AIUsageEvent rows found. Has scripts/setup-ai-usage-schema.js been run, and has " +
        "the backend been deployed and used since?"
    );
    return;
  }
  printReport(summarize(events), events, days);
}

main().catch((err) => {
  console.error("Report failed:", err.message);
  process.exit(1);
});
