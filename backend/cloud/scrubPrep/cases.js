// A user's saved Cases (completed OR Preps), stored server-side as a `ScrubCase` Parse
// class scoped to `owner` (Pointer<_User>) — the backend is the single source of truth,
// not the device. At most one row per (owner, normalizedDescription): see upsertCase,
// which updates + re-dates an existing match instead of inserting a duplicate (mirrors
// the client-side CaseHistoryStore.addOrUpdate logic this replaces).
//
// Class-level permissions deny all public/client access (see
// scripts/setup-user-data-schema.js) — every read/write here goes through the Master Key,
// with ownership enforced by an explicit `owner` query constraint rather than ACLs, the
// same pattern the existing (ephemeral) PimpSession class in cloud/main.js already uses.

function normalizeDescription(text) {
  return (text || "").trim().toLowerCase();
}

// Dates are sent as explicit ISO8601 strings rather than raw Date objects — the client
// decodes them defensively itself rather than relying on however the Cloud Function
// response pipeline would otherwise serialize a native Date (untested territory: no
// other Cloud Function response in this app has ever included a Date field before).
function serializeCase(obj) {
  const lastReviewedAt = obj.get("lastReviewedAt");
  const specialty = obj.get("specialty");
  return {
    id: obj.id,
    caseDescription: obj.get("caseDescription"),
    prep: obj.get("prep") || null,
    // Pointer<Specialty> the case was prepared under — null for cases saved before this
    // field existed, or prepared with no specialty selected.
    specialty: specialty ? { id: specialty.id, name: specialty.get("name") } : null,
    // The student's own free-text notes on this case ("" when none). Untouched by
    // upsertCase, so re-preparing the same case keeps them.
    notes: obj.get("notes") || "",
    createdAt: obj.createdAt.toISOString(),
    updatedAt: obj.updatedAt.toISOString(),
    lastReviewedAt: lastReviewedAt ? lastReviewedAt.toISOString() : null,
  };
}

async function fetchCaseObject({ owner, normalizedDescription }) {
  const query = new Parse.Query("ScrubCase");
  query.equalTo("owner", owner);
  query.equalTo("normalizedDescription", normalizedDescription);
  query.include("specialty");
  return query.first({ useMasterKey: true });
}

async function fetchCasesForOwner(owner) {
  const query = new Parse.Query("ScrubCase");
  query.equalTo("owner", owner);
  query.descending("updatedAt");
  query.include("specialty");
  query.limit(200);
  return query.find({ useMasterKey: true });
}

async function fetchOwnedCaseById({ caseId, owner }) {
  const query = new Parse.Query("ScrubCase");
  query.equalTo("objectId", caseId);
  query.equalTo("owner", owner);
  query.include("specialty");
  return query.first({ useMasterKey: true });
}

/** @returns {Promise<Parse.Object|null>} the Specialty row, or null if it doesn't exist. */
async function fetchSpecialtyById(specialtyId) {
  const query = new Parse.Query("Specialty");
  try {
    return await query.get(specialtyId, { useMasterKey: true });
  } catch (err) {
    if (err && err.code === Parse.Error.OBJECT_NOT_FOUND) return null;
    throw err;
  }
}

function newCaseObject() {
  const ScrubCaseClass = Parse.Object.extend("ScrubCase");
  return new ScrubCaseClass();
}

/**
 * Inserts a new case for `owner`, or — if the same (normalized) case description was
 * already saved for them — updates and re-dates that existing row instead. Never
 * duplicates.
 *
 * `specialty` (a fetched Specialty object) is only written when provided, so re-saving a
 * case without one keeps whatever specialty it was originally prepared under.
 *
 * @param {{ owner: Parse.User, caseDescription: string, prep: object, specialty?: Parse.Object|null }} params
 * @param {{ fetchCaseObject?: typeof fetchCaseObject, newCaseObject?: typeof newCaseObject }} [deps]
 */
async function upsertCase({ owner, caseDescription, prep, specialty }, deps = {}) {
  const fetch = deps.fetchCaseObject || fetchCaseObject;
  const createNew = deps.newCaseObject || newCaseObject;
  const normalizedDescription = normalizeDescription(caseDescription);
  const existing = await fetch({ owner, normalizedDescription });

  const scrubCase = existing || createNew();
  scrubCase.set("owner", owner);
  scrubCase.set("caseDescription", caseDescription);
  scrubCase.set("normalizedDescription", normalizedDescription);
  scrubCase.set("prep", prep || null);
  if (specialty) {
    scrubCase.set("specialty", specialty);
  }
  if (existing) {
    scrubCase.set("lastReviewedAt", null);
  }
  await scrubCase.save(null, { useMasterKey: true });
  return serializeCase(scrubCase);
}

/**
 * @param {Parse.User} owner
 * @param {{ fetchCasesForOwner?: typeof fetchCasesForOwner }} [deps]
 */
async function listCasesForOwner(owner, deps = {}) {
  const fetch = deps.fetchCasesForOwner || fetchCasesForOwner;
  const objects = await fetch(owner);
  return objects.map(serializeCase);
}

/**
 * @param {{ caseId: string, owner: Parse.User }} params
 * @param {{ fetchOwnedCaseById?: typeof fetchOwnedCaseById }} [deps]
 * @returns {Promise<object|null>} the updated case, or null if it wasn't found/owned.
 */
async function markCaseReviewed({ caseId, owner }, deps = {}) {
  const fetch = deps.fetchOwnedCaseById || fetchOwnedCaseById;
  const scrubCase = await fetch({ caseId, owner });
  if (!scrubCase) return null;
  scrubCase.set("lastReviewedAt", new Date());
  await scrubCase.save(null, { useMasterKey: true });
  return serializeCase(scrubCase);
}

/**
 * Replaces the case's notes. An empty string clears them.
 *
 * @param {{ caseId: string, owner: Parse.User, notes: string }} params
 * @param {{ fetchOwnedCaseById?: typeof fetchOwnedCaseById }} [deps]
 * @returns {Promise<object|null>} the updated case, or null if it wasn't found/owned.
 */
async function updateCaseNotes({ caseId, owner, notes }, deps = {}) {
  const fetch = deps.fetchOwnedCaseById || fetchOwnedCaseById;
  const scrubCase = await fetch({ caseId, owner });
  if (!scrubCase) return null;
  scrubCase.set("notes", notes);
  await scrubCase.save(null, { useMasterKey: true });
  return serializeCase(scrubCase);
}

/**
 * Deletes the case and cascades to any completed Pimp Me sessions for the same
 * (owner, normalizedDescription) — an orphaned session for a case that no longer
 * exists serves no purpose.
 *
 * @param {{ caseId: string, owner: Parse.User }} params
 * @param {{ fetchOwnedCaseById?: typeof fetchOwnedCaseById, deleteSessionsForCase?: Function }} [deps]
 * @returns {Promise<boolean>} whether a case was found and deleted.
 */
async function deleteCase({ caseId, owner }, deps = {}) {
  const fetch = deps.fetchOwnedCaseById || fetchOwnedCaseById;
  const scrubCase = await fetch({ caseId, owner });
  if (!scrubCase) return false;

  const normalizedDescription = scrubCase.get("normalizedDescription");
  await scrubCase.destroy({ useMasterKey: true });

  const cascadeDelete = deps.deleteSessionsForCase || require("./pimpMeSessions").deleteSessionsForCase;
  await cascadeDelete({ owner, normalizedDescription });
  return true;
}

module.exports = {
  normalizeDescription,
  fetchCaseObject,
  fetchCasesForOwner,
  fetchOwnedCaseById,
  fetchSpecialtyById,
  upsertCase,
  listCasesForOwner,
  markCaseReviewed,
  updateCaseNotes,
  deleteCase,
};
