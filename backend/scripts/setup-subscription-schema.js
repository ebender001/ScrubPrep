#!/usr/bin/env node
// Creates (or updates) the UserEntitlement and ComplimentaryReservation Parse classes
// with Class-Level Permissions locked down entirely — no public/client access at all —
// same pattern as scripts/setup-user-data-schema.js. Only ever touched from Cloud Code
// using the Master Key (see cloud/scrubPrep/subscriptions.js).
//
// Safe to re-run: POSTs to create each class, and falls back to PUT (update) if it
// already exists.
//
// Usage (reads backend/.env if present): node scripts/setup-subscription-schema.js

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
    className: "UserEntitlement",
    fields: {
      owner: { type: "Pointer", targetClass: "_User" },
      appAccountToken: { type: "String" },
      subscriptionStatus: { type: "String" },
      subscriptionProductId: { type: "String" },
      subscriptionExpiresAt: { type: "Date" },
      subscriptionGracePeriodExpiresAt: { type: "Date" },
      subscriptionRevokedAt: { type: "Date" },
      subscriptionAutoRenewStatus: { type: "Boolean" },
      subscriptionAutoRenewProductId: { type: "String" },
      subscriptionOriginalTransactionId: { type: "String" },
      subscriptionLastSignedDate: { type: "Number" },
      lastVerifiedAt: { type: "Date" },
      createdAtVerified: { type: "Date" },
    },
  },
  {
    className: "ComplimentaryReservation",
    fields: {
      owner: { type: "Pointer", targetClass: "_User" },
      status: { type: "String" },
      requestToken: { type: "String" },
      reservedAt: { type: "Date" },
      caseId: { type: "String" },
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
  console.log(
    "\nRecommended (optional, one-time) hardening: in the Back4App Database Browser, add " +
      "a unique index on ComplimentaryReservation.owner if the UI exposes that option — " +
      "the app already enforces this via a beforeSave guard, this just adds a second, " +
      "database-level layer. See cloud/scrubPrep/subscriptions.js's file comment."
  );
}

main().catch((err) => {
  console.error("Schema setup failed:", err.message);
  process.exit(1);
});
