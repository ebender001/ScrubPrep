#!/usr/bin/env node
// Adds the subscription/complimentary-case fields to the built-in `_User` class. Unlike
// scripts/setup-user-data-schema.js's classes, these fields live on `_User` itself rather
// than a separate Parse class (see cloud/scrubPrep/subscriptions.js for why), and don't
// need their own Class-Level Permissions — `_User`'s existing CLP already governs
// create/update at the object level, and cloud/scrubPrep/subscriptions.js's beforeSave
// guard (registerProtectedFieldsGuard) is what stops a client from writing these specific
// fields directly, not a CLP (Parse Server CLPs don't support per-field write rules).
//
// Safe to re-run: PUTs the field definitions onto the existing _User schema.
//
// Usage (reads backend/.env if present): node scripts/setup-user-subscription-fields.js

const { loadContext, restRequest } = require("./lib/parseRest");

const FIELDS = {
  hasUsedComplimentaryCase: { type: "Boolean" },
  subscriptionStatus: { type: "String" },
  subscriptionProductId: { type: "String" },
  subscriptionExpiresAt: { type: "Date" },
  subscriptionGracePeriodExpiresAt: { type: "Date" },
  subscriptionAutoRenewStatus: { type: "Boolean" },
  subscriptionAutoRenewProductId: { type: "String" },
  subscriptionOriginalTransactionId: { type: "String" },
  subscriptionLastReportedAt: { type: "Date" },
};

async function main() {
  const ctx = loadContext();
  await restRequest({ method: "PUT", pathname: "schemas/_User", body: { className: "_User", fields: FIELDS }, ...ctx });
  console.log("Updated _User schema with subscription fields.");
}

main().catch((err) => {
  console.error("Schema setup failed:", err.message);
  process.exit(1);
});
