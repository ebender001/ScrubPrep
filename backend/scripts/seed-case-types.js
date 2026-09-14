#!/usr/bin/env node
// Rebuilds the `CaseType` Parse class from the CASE_TYPES list below, with `specialty` as a
// Pointer<Specialty> (resolved via seed-specialties.js). Safe to re-run.
//
// This *deletes and recreates* every CaseType row (rather than upserting in place) because
// earlier versions of this catalog stored `specialty` as a plain String column, and Parse
// Server's schema locks a field to whichever type it first saw — writing a Pointer into a
// column the schema thinks is a String fails. Deleting all rows first and dropping the class
// schema lets it get re-inferred fresh as a Pointer. CaseType is pure seed data (nothing else
// references these objectIds), so this is safe.
//
// Usage (reads backend/.env if present): node scripts/seed-case-types.js

const { loadContext, restRequest } = require("./lib/parseRest");
const { upsertSpecialties } = require("./seed-specialties");

const CASE_TYPES = [
  { name: "Lap Chole", specialtyName: "General Surgery", sortOrder: 1, featured: true },
  { name: "Appendectomy", specialtyName: "General Surgery", sortOrder: 2, featured: true },
  { name: "Inguinal Hernia", specialtyName: "General Surgery", sortOrder: 3, featured: true },
  { name: "Colectomy", specialtyName: "General Surgery", sortOrder: 4, featured: true },
  { name: "CABG", specialtyName: "Cardiac Surgery", sortOrder: 1, featured: false },
  { name: "Tonsillectomy", specialtyName: "ENT", sortOrder: 1, featured: false },
  { name: "Septoplasty", specialtyName: "ENT", sortOrder: 2, featured: false },
  { name: "TURP", specialtyName: "Urology", sortOrder: 1, featured: false },
  { name: "Nephrectomy", specialtyName: "Urology", sortOrder: 2, featured: false },
  { name: "Total Knee Arthroplasty", specialtyName: "Orthopedics", sortOrder: 1, featured: false },
  { name: "ACL Reconstruction", specialtyName: "Orthopedics", sortOrder: 2, featured: false },
];

async function deleteAllCaseTypes(ctx) {
  const existing = await restRequest({ method: "GET", pathname: "classes/CaseType?limit=1000", ...ctx });
  for (const row of existing.results || []) {
    await restRequest({ method: "DELETE", pathname: `classes/CaseType/${row.objectId}`, ...ctx });
  }
  if (existing.results && existing.results.length > 0) {
    console.log(`Deleted ${existing.results.length} existing CaseType row(s).`);
  }
}

async function dropCaseTypeSchema(ctx) {
  try {
    await restRequest({ method: "DELETE", pathname: "schemas/CaseType", ...ctx });
    console.log("Dropped stale CaseType schema (specialty was a String; rebuilding as a Pointer).");
  } catch (err) {
    // Fine if the class didn't exist yet (first-ever run) — nothing to drop.
    if (!/class.*not found|103/i.test(err.message)) throw err;
  }
}

async function createCaseType(caseType, specialtyId, ctx) {
  await restRequest({
    method: "POST",
    pathname: "classes/CaseType",
    body: {
      name: caseType.name,
      specialty: { __type: "Pointer", className: "Specialty", objectId: specialtyId },
      sortOrder: caseType.sortOrder,
      featured: caseType.featured,
    },
    ...ctx,
  });
  console.log(`Created: ${caseType.name}`);
}

async function main() {
  const ctx = loadContext();
  await deleteAllCaseTypes(ctx);
  await dropCaseTypeSchema(ctx);

  const specialtyIdByName = await upsertSpecialties(ctx);

  for (const caseType of CASE_TYPES) {
    const specialtyId = specialtyIdByName[caseType.specialtyName];
    if (!specialtyId) {
      throw new Error(`No seeded specialty found for "${caseType.specialtyName}" (case type "${caseType.name}")`);
    }
    await createCaseType(caseType, specialtyId, ctx);
  }
  console.log(`Done. Seeded ${CASE_TYPES.length} case types.`);
}

main().catch((err) => {
  console.error("Seeding failed:", err.message);
  process.exit(1);
});
