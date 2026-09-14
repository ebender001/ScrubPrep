// Specialty catalog, stored server-side as a `Specialty` Parse class. `CaseType.specialty`
// is a Pointer to a row here (see cloud/scrubPrep/caseTypes.js) rather than a raw string, so
// the human-readable name can be edited/reordered without touching every CaseType row.

async function fetchSpecialtyObjects() {
  const query = new Parse.Query("Specialty");
  query.ascending("sortOrder");
  query.addAscending("name");
  query.limit(200);
  return query.find({ useMasterKey: true });
}

/**
 * Returns the specialty catalog as plain { id, name, exampleCaseDescription } objects,
 * sorted by sortOrder/name.
 *
 * @param {{ fetchSpecialtyObjects?: typeof fetchSpecialtyObjects }} [deps]
 */
async function listSpecialties(deps = {}) {
  const fetch = deps.fetchSpecialtyObjects || fetchSpecialtyObjects;
  const objects = await fetch();
  return objects.map((obj) => ({
    id: obj.id,
    name: obj.get("name"),
    exampleCaseDescription: obj.get("exampleCaseDescription") || "",
  }));
}

module.exports = { listSpecialties, fetchSpecialtyObjects };
