#!/usr/bin/env node
// Idempotently seeds the `CaseType` Parse class with the initial case catalog, grouped by
// specialty. Safe to re-run: upserts by `name` (updates specialty/sortOrder/featured if the
// row already exists, creates it otherwise). Talks to the Parse REST API directly with the
// Master Key, same pattern as call-cloud-function.js.
//
// Usage (reads backend/.env if present):
//   node scripts/seed-case-types.js
//
// Or override via environment inline:
//   PARSE_APP_ID=... PARSE_MASTER_KEY=... node scripts/seed-case-types.js

const https = require("https");
const fs = require("fs");
const path = require("path");
const { URL } = require("url");

function loadDotEnv() {
  const envPath = path.join(__dirname, "..", ".env");
  if (!fs.existsSync(envPath)) return;
  const lines = fs.readFileSync(envPath, "utf8").split("\n");
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const eq = trimmed.indexOf("=");
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    const value = trimmed.slice(eq + 1).trim();
    if (!(key in process.env)) process.env[key] = value;
  }
}

// Keep in sync with cloud/scrubPrep/caseTypes.js's SPECIALTIES keys.
const CASE_TYPES = [
  { name: "Lap Chole", specialty: "general_surgery", sortOrder: 1, featured: true },
  { name: "Appendectomy", specialty: "general_surgery", sortOrder: 2, featured: true },
  { name: "Inguinal Hernia", specialty: "general_surgery", sortOrder: 3, featured: true },
  { name: "Colectomy", specialty: "general_surgery", sortOrder: 4, featured: true },
  { name: "CABG", specialty: "cardiothoracic", sortOrder: 1, featured: false },
  { name: "Tonsillectomy", specialty: "ent", sortOrder: 1, featured: false },
  { name: "Septoplasty", specialty: "ent", sortOrder: 2, featured: false },
  { name: "TURP", specialty: "urology", sortOrder: 1, featured: false },
  { name: "Nephrectomy", specialty: "urology", sortOrder: 2, featured: false },
  { name: "Total Knee Arthroplasty", specialty: "orthopedics", sortOrder: 1, featured: false },
  { name: "ACL Reconstruction", specialty: "orthopedics", sortOrder: 2, featured: false },
];

function restRequest({ method, pathname, appId, masterKey, serverUrl, body }) {
  return new Promise((resolve, reject) => {
    const base = serverUrl.endsWith("/") ? serverUrl : serverUrl + "/";
    const url = new URL(pathname, base);
    const payload = body ? JSON.stringify(body) : undefined;
    const req = https.request(
      {
        hostname: url.hostname,
        path: url.pathname + url.search,
        method,
        headers: {
          "Content-Type": "application/json",
          "X-Parse-Application-Id": appId,
          "X-Parse-Master-Key": masterKey,
          ...(payload ? { "Content-Length": Buffer.byteLength(payload) } : {}),
        },
      },
      (res) => {
        let data = "";
        res.on("data", (chunk) => (data += chunk));
        res.on("end", () => {
          let parsed;
          try {
            parsed = data ? JSON.parse(data) : {};
          } catch {
            parsed = {};
          }
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(parsed);
          } else {
            reject(new Error(`HTTP ${res.statusCode}: ${data}`));
          }
        });
      }
    );
    req.on("error", reject);
    if (payload) req.write(payload);
    req.end();
  });
}

async function upsertCaseType(caseType, ctx) {
  const where = encodeURIComponent(JSON.stringify({ name: caseType.name }));
  const existing = await restRequest({
    method: "GET",
    pathname: `classes/CaseType?where=${where}`,
    ...ctx,
  });
  const fields = {
    specialty: caseType.specialty,
    sortOrder: caseType.sortOrder,
    featured: caseType.featured,
  };

  if (existing.results && existing.results.length > 0) {
    const objectId = existing.results[0].objectId;
    await restRequest({ method: "PUT", pathname: `classes/CaseType/${objectId}`, body: fields, ...ctx });
    console.log(`Updated: ${caseType.name}`);
  } else {
    await restRequest({
      method: "POST",
      pathname: "classes/CaseType",
      body: { name: caseType.name, ...fields },
      ...ctx,
    });
    console.log(`Created: ${caseType.name}`);
  }
}

async function main() {
  loadDotEnv();
  const appId = process.env.PARSE_APP_ID;
  const masterKey = process.env.PARSE_MASTER_KEY;
  const serverUrl = process.env.PARSE_SERVER_URL || "https://parseapi.back4app.com/";
  if (!appId || !masterKey) {
    console.error(
      "Set PARSE_APP_ID and PARSE_MASTER_KEY — either in backend/.env or inline in your environment."
    );
    process.exit(1);
  }

  const ctx = { appId, masterKey, serverUrl };
  for (const caseType of CASE_TYPES) {
    await upsertCaseType(caseType, ctx);
  }
  console.log(`Done. Seeded ${CASE_TYPES.length} case types.`);
}

main().catch((err) => {
  console.error("Seeding failed:", err.message);
  process.exit(1);
});
