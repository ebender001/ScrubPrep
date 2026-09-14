// Case type catalog, stored server-side as a `CaseType` Parse class so the list can be
// curated/expanded without an app release. Each row: { name, specialty, sortOrder, featured }.

const SPECIALTIES = [
  { key: "general_surgery", label: "General Surgery" },
  { key: "cardiothoracic", label: "Cardiothoracic" },
  { key: "ent", label: "ENT" },
  { key: "urology", label: "Urology" },
  { key: "orthopedics", label: "Orthopedics" },
];

async function fetchCaseTypeObjects() {
  const query = new Parse.Query("CaseType");
  query.ascending("specialty");
  query.addAscending("sortOrder");
  query.addAscending("name");
  query.limit(500);
  return query.find({ useMasterKey: true });
}

/**
 * Returns the case type catalog as plain objects, sorted by specialty then sortOrder/name.
 *
 * @param {{ fetchCaseTypeObjects?: typeof fetchCaseTypeObjects }} [deps]
 */
async function listCaseTypes(deps = {}) {
  const fetch = deps.fetchCaseTypeObjects || fetchCaseTypeObjects;
  const objects = await fetch();
  return objects.map((obj) => ({
    name: obj.get("name"),
    specialty: obj.get("specialty"),
    featured: !!obj.get("featured"),
  }));
}

module.exports = { SPECIALTIES, listCaseTypes, fetchCaseTypeObjects };
