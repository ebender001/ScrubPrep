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
  // General Surgery — the original 4 stay featured (Home screen default quick-picks).
  { name: "Lap Chole", specialtyName: "General Surgery", sortOrder: 1, featured: true },
  { name: "Appendectomy", specialtyName: "General Surgery", sortOrder: 2, featured: true },
  { name: "Inguinal Hernia", specialtyName: "General Surgery", sortOrder: 3, featured: true },
  { name: "Colectomy", specialtyName: "General Surgery", sortOrder: 4, featured: true },
  { name: "Umbilical Hernia Repair", specialtyName: "General Surgery", sortOrder: 5, featured: false },
  { name: "Ventral Hernia Repair", specialtyName: "General Surgery", sortOrder: 6, featured: false },
  { name: "Small Bowel Resection", specialtyName: "General Surgery", sortOrder: 7, featured: false },
  { name: "Whipple Procedure", specialtyName: "General Surgery", sortOrder: 8, featured: false },
  { name: "Splenectomy", specialtyName: "General Surgery", sortOrder: 9, featured: false },
  { name: "Nissen Fundoplication", specialtyName: "General Surgery", sortOrder: 10, featured: false },
  { name: "Thyroidectomy", specialtyName: "General Surgery", sortOrder: 11, featured: false },
  { name: "Roux-en-Y Gastric Bypass", specialtyName: "General Surgery", sortOrder: 12, featured: false },
  { name: "Sleeve Gastrectomy", specialtyName: "General Surgery", sortOrder: 13, featured: false },
  { name: "Exploratory Laparotomy", specialtyName: "General Surgery", sortOrder: 14, featured: false },

  // Cardiac Surgery
  { name: "CABG", specialtyName: "Cardiac Surgery", sortOrder: 1, featured: false },
  { name: "Aortic Valve Replacement", specialtyName: "Cardiac Surgery", sortOrder: 2, featured: false },
  { name: "Mitral Valve Repair", specialtyName: "Cardiac Surgery", sortOrder: 3, featured: false },
  { name: "Mitral Valve Replacement", specialtyName: "Cardiac Surgery", sortOrder: 4, featured: false },
  { name: "TAVR", specialtyName: "Cardiac Surgery", sortOrder: 5, featured: false },
  { name: "Ascending Aortic Aneurysm Repair", specialtyName: "Cardiac Surgery", sortOrder: 6, featured: false },
  { name: "Maze Procedure", specialtyName: "Cardiac Surgery", sortOrder: 7, featured: false },
  { name: "LVAD Placement", specialtyName: "Cardiac Surgery", sortOrder: 8, featured: false },
  { name: "Pericardiectomy", specialtyName: "Cardiac Surgery", sortOrder: 9, featured: false },

  // Thoracic Surgery
  { name: "Lobectomy", specialtyName: "Thoracic Surgery", sortOrder: 1, featured: false },
  { name: "Pneumonectomy", specialtyName: "Thoracic Surgery", sortOrder: 2, featured: false },
  { name: "Wedge Resection", specialtyName: "Thoracic Surgery", sortOrder: 3, featured: false },
  { name: "VATS Wedge Resection", specialtyName: "Thoracic Surgery", sortOrder: 4, featured: false },
  { name: "Esophagectomy", specialtyName: "Thoracic Surgery", sortOrder: 5, featured: false },
  { name: "Mediastinoscopy", specialtyName: "Thoracic Surgery", sortOrder: 6, featured: false },
  { name: "Decortication", specialtyName: "Thoracic Surgery", sortOrder: 7, featured: false },
  { name: "Thymectomy", specialtyName: "Thoracic Surgery", sortOrder: 8, featured: false },
  { name: "Tracheostomy", specialtyName: "Thoracic Surgery", sortOrder: 9, featured: false },

  // ENT
  { name: "Tonsillectomy", specialtyName: "ENT", sortOrder: 1, featured: false },
  { name: "Septoplasty", specialtyName: "ENT", sortOrder: 2, featured: false },
  { name: "Adenoidectomy", specialtyName: "ENT", sortOrder: 3, featured: false },
  { name: "Myringotomy with Tube Placement", specialtyName: "ENT", sortOrder: 4, featured: false },
  { name: "Tympanoplasty", specialtyName: "ENT", sortOrder: 5, featured: false },
  { name: "Mastoidectomy", specialtyName: "ENT", sortOrder: 6, featured: false },
  { name: "Functional Endoscopic Sinus Surgery", specialtyName: "ENT", sortOrder: 7, featured: false },
  { name: "Parotidectomy", specialtyName: "ENT", sortOrder: 8, featured: false },
  { name: "Neck Dissection", specialtyName: "ENT", sortOrder: 9, featured: false },
  { name: "Laryngectomy", specialtyName: "ENT", sortOrder: 10, featured: false },
  { name: "Uvulopalatopharyngoplasty", specialtyName: "ENT", sortOrder: 11, featured: false },

  // Urology
  { name: "TURP", specialtyName: "Urology", sortOrder: 1, featured: false },
  { name: "Nephrectomy", specialtyName: "Urology", sortOrder: 2, featured: false },
  { name: "Radical Prostatectomy", specialtyName: "Urology", sortOrder: 3, featured: false },
  { name: "Cystectomy", specialtyName: "Urology", sortOrder: 4, featured: false },
  { name: "Ureteroscopy with Laser Lithotripsy", specialtyName: "Urology", sortOrder: 5, featured: false },
  { name: "Percutaneous Nephrolithotomy", specialtyName: "Urology", sortOrder: 6, featured: false },
  { name: "Circumcision", specialtyName: "Urology", sortOrder: 7, featured: false },
  { name: "Vasectomy", specialtyName: "Urology", sortOrder: 8, featured: false },
  { name: "Orchiectomy", specialtyName: "Urology", sortOrder: 9, featured: false },
  { name: "Pyeloplasty", specialtyName: "Urology", sortOrder: 10, featured: false },
  { name: "Transurethral Resection of Bladder Tumor", specialtyName: "Urology", sortOrder: 11, featured: false },

  // Orthopedics
  { name: "Total Knee Arthroplasty", specialtyName: "Orthopedics", sortOrder: 1, featured: false },
  { name: "ACL Reconstruction", specialtyName: "Orthopedics", sortOrder: 2, featured: false },
  { name: "Total Hip Arthroplasty", specialtyName: "Orthopedics", sortOrder: 3, featured: false },
  { name: "Rotator Cuff Repair", specialtyName: "Orthopedics", sortOrder: 4, featured: false },
  { name: "Hip Fracture ORIF", specialtyName: "Orthopedics", sortOrder: 5, featured: false },
  { name: "Ankle Fracture ORIF", specialtyName: "Orthopedics", sortOrder: 6, featured: false },
  { name: "Lumbar Spinal Fusion", specialtyName: "Orthopedics", sortOrder: 7, featured: false },
  { name: "Carpal Tunnel Release", specialtyName: "Orthopedics", sortOrder: 8, featured: false },
  { name: "Meniscus Repair", specialtyName: "Orthopedics", sortOrder: 9, featured: false },
  { name: "Shoulder Arthroplasty", specialtyName: "Orthopedics", sortOrder: 10, featured: false },
  { name: "Distal Radius Fracture ORIF", specialtyName: "Orthopedics", sortOrder: 11, featured: false },
  { name: "Laminectomy", specialtyName: "Orthopedics", sortOrder: 12, featured: false },
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
