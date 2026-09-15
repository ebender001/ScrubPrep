#!/usr/bin/env node
// Creates (or updates) the ScrubCase and PimpMeSession Parse classes with Class-Level
// Permissions locked down entirely — no public/client access at all, find/get/create/
// update/delete/addField all `{}`. These classes are only ever touched from Cloud Code
// using the Master Key (see cloud/scrubPrep/cases.js and cloud/scrubPrep/pimpMeSessions.js),
// the same pattern the existing (ephemeral) PimpSession class already uses.
//
// Safe to re-run: POSTs to create the class, and falls back to PUT (update) if it already
// exists.
//
// Usage (reads backend/.env if present): node scripts/setup-user-data-schema.js

const { loadContext, restRequest } = require("./lib/parseRest");

const NO_PUBLIC_ACCESS_CLP = {
  find: {},
  get: {},
  create: {},
  update: {},
  delete: {},
  addField: {},
};

const SCHEMAS = [
  {
    className: "ScrubCase",
    fields: {
      owner: { type: "Pointer", targetClass: "_User" },
      caseDescription: { type: "String" },
      normalizedDescription: { type: "String" },
      prep: { type: "Object" },
      lastReviewedAt: { type: "Date" },
    },
  },
  {
    className: "PimpMeSession",
    fields: {
      owner: { type: "Pointer", targetClass: "_User" },
      caseDescription: { type: "String" },
      normalizedDescription: { type: "String" },
      difficulty: { type: "String" },
      transcript: { type: "Array" },
      summary: { type: "Object" },
      completedAt: { type: "Date" },
    },
  },
];

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
  for (const schema of SCHEMAS) {
    await createOrUpdateSchema(schema, ctx);
  }
  console.log("Done.");
}

main().catch((err) => {
  console.error("Schema setup failed:", err.message);
  process.exit(1);
});
