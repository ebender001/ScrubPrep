#!/usr/bin/env node
// Adds the complimentary-case field to the built-in `_User` class. Lives on `_User`
// itself rather than a separate Parse class (see cloud/scrubPrep/subscriptions.js), and
// doesn't need its own Class-Level Permissions — `_User`'s existing CLP already governs
// create/update at the object level, and cloud/scrubPrep/subscriptions.js's beforeSave
// guard (registerProtectedFieldsGuard) is what stops a client from writing this field
// directly, not a CLP (Parse Server CLPs don't support per-field write rules).
//
// Note: this project previously also stored appAccountToken/subscriptionStatus/etc. on
// _User, back when the backend independently tracked reported subscription state. That
// design was replaced with an on-device-only StoreKit 2 check (see
// SubscriptionManager.swift) — those columns may still exist on already-deployed
// databases as harmless, unused leftovers; this script no longer declares them.
//
// Safe to re-run: PUTs the field definition onto the existing _User schema.
//
// Usage (reads backend/.env if present): node scripts/setup-user-subscription-fields.js

const { loadContext, restRequest } = require("./lib/parseRest");

const FIELDS = {
  hasUsedComplimentaryCase: { type: "Boolean" },
};

async function main() {
  const ctx = loadContext();
  await restRequest({ method: "PUT", pathname: "schemas/_User", body: { className: "_User", fields: FIELDS }, ...ctx });
  console.log("Updated _User schema with the complimentary-case field.");
}

main().catch((err) => {
  console.error("Schema setup failed:", err.message);
  process.exit(1);
});
