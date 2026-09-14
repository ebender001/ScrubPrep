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
  { name: "Lap Chole", fullName: "Laparoscopic Cholecystectomy", specialtyName: "General Surgery", sortOrder: 1, featured: true },
  { name: "Appendectomy", fullName: "Appendectomy", specialtyName: "General Surgery", sortOrder: 2, featured: true },
  { name: "Inguinal Hernia", fullName: "Inguinal Hernia Repair", specialtyName: "General Surgery", sortOrder: 3, featured: true },
  { name: "Colectomy", fullName: "Colectomy", specialtyName: "General Surgery", sortOrder: 4, featured: true },
  { name: "Umbilical Hernia Repair", fullName: "Umbilical Hernia Repair", specialtyName: "General Surgery", sortOrder: 5, featured: false },
  { name: "Ventral Hernia Repair", fullName: "Ventral Hernia Repair", specialtyName: "General Surgery", sortOrder: 6, featured: false },
  { name: "Small Bowel Resection", fullName: "Small Bowel Resection", specialtyName: "General Surgery", sortOrder: 7, featured: false },
  { name: "Whipple Procedure", fullName: "Pancreaticoduodenectomy (Whipple Procedure)", specialtyName: "General Surgery", sortOrder: 8, featured: false },
  { name: "Splenectomy", fullName: "Splenectomy", specialtyName: "General Surgery", sortOrder: 9, featured: false },
  { name: "Nissen Fundoplication", fullName: "Nissen Fundoplication", specialtyName: "General Surgery", sortOrder: 10, featured: false },
  { name: "Thyroidectomy", fullName: "Thyroidectomy", specialtyName: "General Surgery", sortOrder: 11, featured: false },
  { name: "Roux-en-Y Gastric Bypass", fullName: "Roux-en-Y Gastric Bypass", specialtyName: "General Surgery", sortOrder: 12, featured: false },
  { name: "Sleeve Gastrectomy", fullName: "Sleeve Gastrectomy", specialtyName: "General Surgery", sortOrder: 13, featured: false },
  { name: "Exploratory Laparotomy", fullName: "Exploratory Laparotomy", specialtyName: "General Surgery", sortOrder: 14, featured: false },

  // Cardiac Surgery
  { name: "CABG", fullName: "Coronary Artery Bypass Grafting", specialtyName: "Cardiac Surgery", sortOrder: 1, featured: false },
  { name: "Aortic Valve Replacement", fullName: "Aortic Valve Replacement", specialtyName: "Cardiac Surgery", sortOrder: 2, featured: false },
  { name: "Mitral Valve Repair", fullName: "Mitral Valve Repair", specialtyName: "Cardiac Surgery", sortOrder: 3, featured: false },
  { name: "Mitral Valve Replacement", fullName: "Mitral Valve Replacement", specialtyName: "Cardiac Surgery", sortOrder: 4, featured: false },
  { name: "TAVR", fullName: "Transcatheter Aortic Valve Replacement", specialtyName: "Cardiac Surgery", sortOrder: 5, featured: false },
  { name: "Ascending Aortic Aneurysm Repair", fullName: "Ascending Aortic Aneurysm Repair", specialtyName: "Cardiac Surgery", sortOrder: 6, featured: false },
  { name: "Maze Procedure", fullName: "Maze Procedure for Atrial Fibrillation", specialtyName: "Cardiac Surgery", sortOrder: 7, featured: false },
  { name: "LVAD Placement", fullName: "Left Ventricular Assist Device (LVAD) Placement", specialtyName: "Cardiac Surgery", sortOrder: 8, featured: false },
  { name: "Pericardiectomy", fullName: "Pericardiectomy", specialtyName: "Cardiac Surgery", sortOrder: 9, featured: false },

  // Thoracic Surgery
  { name: "Lobectomy", fullName: "Pulmonary Lobectomy", specialtyName: "Thoracic Surgery", sortOrder: 1, featured: false },
  { name: "Pneumonectomy", fullName: "Pneumonectomy", specialtyName: "Thoracic Surgery", sortOrder: 2, featured: false },
  { name: "Wedge Resection", fullName: "Pulmonary Wedge Resection", specialtyName: "Thoracic Surgery", sortOrder: 3, featured: false },
  { name: "VATS Wedge Resection", fullName: "Video-Assisted Thoracoscopic (VATS) Wedge Resection", specialtyName: "Thoracic Surgery", sortOrder: 4, featured: false },
  { name: "Esophagectomy", fullName: "Esophagectomy", specialtyName: "Thoracic Surgery", sortOrder: 5, featured: false },
  { name: "Mediastinoscopy", fullName: "Mediastinoscopy", specialtyName: "Thoracic Surgery", sortOrder: 6, featured: false },
  { name: "Decortication", fullName: "Pulmonary Decortication", specialtyName: "Thoracic Surgery", sortOrder: 7, featured: false },
  { name: "Thymectomy", fullName: "Thymectomy", specialtyName: "Thoracic Surgery", sortOrder: 8, featured: false },
  { name: "Tracheostomy", fullName: "Tracheostomy", specialtyName: "Thoracic Surgery", sortOrder: 9, featured: false },

  // ENT
  { name: "Tonsillectomy", fullName: "Tonsillectomy", specialtyName: "ENT", sortOrder: 1, featured: false },
  { name: "Septoplasty", fullName: "Septoplasty", specialtyName: "ENT", sortOrder: 2, featured: false },
  { name: "Adenoidectomy", fullName: "Adenoidectomy", specialtyName: "ENT", sortOrder: 3, featured: false },
  { name: "Myringotomy with Tube Placement", fullName: "Myringotomy with Tympanostomy Tube Placement", specialtyName: "ENT", sortOrder: 4, featured: false },
  { name: "Tympanoplasty", fullName: "Tympanoplasty", specialtyName: "ENT", sortOrder: 5, featured: false },
  { name: "Mastoidectomy", fullName: "Mastoidectomy", specialtyName: "ENT", sortOrder: 6, featured: false },
  { name: "Functional Endoscopic Sinus Surgery", fullName: "Functional Endoscopic Sinus Surgery (FESS)", specialtyName: "ENT", sortOrder: 7, featured: false },
  { name: "Parotidectomy", fullName: "Parotidectomy", specialtyName: "ENT", sortOrder: 8, featured: false },
  { name: "Neck Dissection", fullName: "Neck Dissection", specialtyName: "ENT", sortOrder: 9, featured: false },
  { name: "Laryngectomy", fullName: "Laryngectomy", specialtyName: "ENT", sortOrder: 10, featured: false },
  { name: "Uvulopalatopharyngoplasty", fullName: "Uvulopalatopharyngoplasty (UPPP)", specialtyName: "ENT", sortOrder: 11, featured: false },

  // Urology
  { name: "TURP", fullName: "Transurethral Resection of the Prostate", specialtyName: "Urology", sortOrder: 1, featured: false },
  { name: "Nephrectomy", fullName: "Nephrectomy", specialtyName: "Urology", sortOrder: 2, featured: false },
  { name: "Radical Prostatectomy", fullName: "Radical Prostatectomy", specialtyName: "Urology", sortOrder: 3, featured: false },
  { name: "Cystectomy", fullName: "Cystectomy", specialtyName: "Urology", sortOrder: 4, featured: false },
  { name: "Ureteroscopy with Laser Lithotripsy", fullName: "Ureteroscopy with Laser Lithotripsy", specialtyName: "Urology", sortOrder: 5, featured: false },
  { name: "Percutaneous Nephrolithotomy", fullName: "Percutaneous Nephrolithotomy (PCNL)", specialtyName: "Urology", sortOrder: 6, featured: false },
  { name: "Circumcision", fullName: "Circumcision", specialtyName: "Urology", sortOrder: 7, featured: false },
  { name: "Vasectomy", fullName: "Vasectomy", specialtyName: "Urology", sortOrder: 8, featured: false },
  { name: "Orchiectomy", fullName: "Orchiectomy", specialtyName: "Urology", sortOrder: 9, featured: false },
  { name: "Pyeloplasty", fullName: "Pyeloplasty", specialtyName: "Urology", sortOrder: 10, featured: false },
  { name: "Transurethral Resection of Bladder Tumor", fullName: "Transurethral Resection of Bladder Tumor (TURBT)", specialtyName: "Urology", sortOrder: 11, featured: false },

  // Orthopedics
  { name: "Total Knee Arthroplasty", fullName: "Total Knee Arthroplasty (Total Knee Replacement)", specialtyName: "Orthopedics", sortOrder: 1, featured: false },
  { name: "ACL Reconstruction", fullName: "Anterior Cruciate Ligament (ACL) Reconstruction", specialtyName: "Orthopedics", sortOrder: 2, featured: false },
  { name: "Total Hip Arthroplasty", fullName: "Total Hip Arthroplasty (Total Hip Replacement)", specialtyName: "Orthopedics", sortOrder: 3, featured: false },
  { name: "Rotator Cuff Repair", fullName: "Rotator Cuff Repair", specialtyName: "Orthopedics", sortOrder: 4, featured: false },
  { name: "Hip Fracture ORIF", fullName: "Open Reduction and Internal Fixation (ORIF) of Hip Fracture", specialtyName: "Orthopedics", sortOrder: 5, featured: false },
  { name: "Ankle Fracture ORIF", fullName: "Open Reduction and Internal Fixation (ORIF) of Ankle Fracture", specialtyName: "Orthopedics", sortOrder: 6, featured: false },
  { name: "Lumbar Spinal Fusion", fullName: "Lumbar Spinal Fusion", specialtyName: "Orthopedics", sortOrder: 7, featured: false },
  { name: "Carpal Tunnel Release", fullName: "Carpal Tunnel Release", specialtyName: "Orthopedics", sortOrder: 8, featured: false },
  { name: "Meniscus Repair", fullName: "Meniscus Repair", specialtyName: "Orthopedics", sortOrder: 9, featured: false },
  { name: "Shoulder Arthroplasty", fullName: "Shoulder Arthroplasty (Shoulder Replacement)", specialtyName: "Orthopedics", sortOrder: 10, featured: false },
  { name: "Distal Radius Fracture ORIF", fullName: "Open Reduction and Internal Fixation (ORIF) of Distal Radius Fracture", specialtyName: "Orthopedics", sortOrder: 11, featured: false },
  { name: "Laminectomy", fullName: "Laminectomy", specialtyName: "Orthopedics", sortOrder: 12, featured: false },
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
      fullName: caseType.fullName,
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
