#!/usr/bin/env node
// Creates (or updates) the AIUsageEvent Parse class with Class-Level Permissions locked
// down entirely — no public/client access at all — same pattern as
// scripts/setup-user-data-schema.js. Only ever written to from Cloud Code using the
// Master Key (see cloud/scrubPrep/aiUsage.js), one row per actual OpenAI API call.
//
// Safe to re-run: POSTs to create the class, and falls back to PUT (update) if it already
// exists.
//
// Usage (reads backend/.env if present): node scripts/setup-ai-usage-schema.js

const { loadContext, restRequest } = require("./lib/parseRest");

const NO_PUBLIC_ACCESS_CLP = {
  find: {},
  get: {},
  create: {},
  update: {},
  delete: {},
  addField: {},
};

const SCHEMA = {
  className: "AIUsageEvent",
  fields: {
    functionName: { type: "String" },
    model: { type: "String" },
    promptTokens: { type: "Number" },
    completionTokens: { type: "Number" },
    totalTokens: { type: "Number" },
    estimatedCostUSD: { type: "Number" },
    owner: { type: "Pointer", targetClass: "_User" },
  },
};

async function createOrUpdateSchema({ className, fields }, ctx) {
  const body = { className, fields, classLevelPermissions: NO_PUBLIC_ACCESS_CLP };
  try {
    await restRequest({ method: "POST", pathname: "schemas", body, ...ctx });
    console.log(`Created ${className} schema.`);
  } catch (err) {
    if (!/already exists|103/i.test(err.message)) throw err;
    await restRequest({ method: "PUT", pathname: `schemas/${className}`, body, ...ctx });
    console.log(`Updated ${className} schema (already existed).`);
  }
}

async function main() {
  const ctx = loadContext();
  await createOrUpdateSchema(SCHEMA, ctx);
  console.log("Done.");
}

main().catch((err) => {
  console.error("Schema setup failed:", err.message);
  process.exit(1);
});
