#!/usr/bin/env node
// Idempotently seeds the `Specialty` Parse class (name, sortOrder) via the Parse REST API,
// upserting by `name`. Exports upsertSpecialties() so seed-case-types.js can seed specialties
// first and get back a name -> objectId map for building CaseType -> Specialty pointers.
//
// Usage (reads backend/.env if present): node scripts/seed-specialties.js

const { loadContext, restRequest } = require("./lib/parseRest");

// Keep in sync with cloud/scrubPrep/specialties.js's expectations (name + sortOrder +
// exampleCaseDescription). exampleCaseDescription is shown in the iOS case-entry field
// before the student has typed anything, once this specialty is selected — see
// Specialty.exampleCaseDescription in the iOS app's Models/CaseType.swift.
const SPECIALTIES = [
  { name: "General Surgery", sortOrder: 1, exampleCaseDescription: "Lap chole for acute cholecystitis" },
  { name: "Cardiac Surgery", sortOrder: 2, exampleCaseDescription: "CABG \u{00D7}3 for multivessel CAD" },
  { name: "Thoracic Surgery", sortOrder: 3, exampleCaseDescription: "VATS right upper lobectomy for lung cancer" },
  { name: "ENT", sortOrder: 4, exampleCaseDescription: "Tonsillectomy for recurrent tonsillitis" },
  { name: "Urology", sortOrder: 5, exampleCaseDescription: "TURP for BPH with urinary retention" },
  { name: "Orthopedics", sortOrder: 6, exampleCaseDescription: "Total knee arthroplasty for end-stage osteoarthritis" },
  { name: "Vascular Surgery", sortOrder: 7, exampleCaseDescription: "CEA for symptomatic carotid stenosis" },
];

async function upsertSpecialty(specialty, ctx) {
  const where = encodeURIComponent(JSON.stringify({ name: specialty.name }));
  const existing = await restRequest({ method: "GET", pathname: `classes/Specialty?where=${where}`, ...ctx });
  const fields = { sortOrder: specialty.sortOrder, exampleCaseDescription: specialty.exampleCaseDescription };

  if (existing.results && existing.results.length > 0) {
    const objectId = existing.results[0].objectId;
    await restRequest({ method: "PUT", pathname: `classes/Specialty/${objectId}`, body: fields, ...ctx });
    console.log(`Updated specialty: ${specialty.name}`);
    return objectId;
  }

  const created = await restRequest({
    method: "POST",
    pathname: "classes/Specialty",
    body: { name: specialty.name, ...fields },
    ...ctx,
  });
  console.log(`Created specialty: ${specialty.name}`);
  return created.objectId;
}

/** Upserts every known specialty, returning a { [name]: objectId } map. */
async function upsertSpecialties(ctx) {
  const nameToId = {};
  for (const specialty of SPECIALTIES) {
    nameToId[specialty.name] = await upsertSpecialty(specialty, ctx);
  }
  return nameToId;
}

async function main() {
  const ctx = loadContext();
  const nameToId = await upsertSpecialties(ctx);
  console.log(`Done. Seeded ${Object.keys(nameToId).length} specialties.`);
}

if (require.main === module) {
  main().catch((err) => {
    console.error("Seeding failed:", err.message);
    process.exit(1);
  });
}

module.exports = { SPECIALTIES, upsertSpecialties };
