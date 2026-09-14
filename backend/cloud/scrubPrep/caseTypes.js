// Case type catalog, stored server-side as a `CaseType` Parse class so the list can be
// curated/expanded without an app release. Each row: { name, specialty (Pointer<Specialty>),
// sortOrder, featured }.

async function fetchCaseTypeObjects() {
  const query = new Parse.Query("CaseType");
  query.include("specialty");
  query.ascending("sortOrder");
  query.addAscending("name");
  query.limit(500);
  return query.find({ useMasterKey: true });
}

/**
 * Returns the case type catalog as plain objects, grouped by specialty (specialty's own
 * sortOrder) then by each case type's sortOrder/name within that specialty.
 *
 * @param {{ fetchCaseTypeObjects?: typeof fetchCaseTypeObjects }} [deps]
 */
async function listCaseTypes(deps = {}) {
  const fetch = deps.fetchCaseTypeObjects || fetchCaseTypeObjects;
  const objects = await fetch();

  const withSortKey = objects.map((obj) => {
    const specialtyObj = obj.get("specialty");
    return {
      item: {
        name: obj.get("name"),
        specialty: specialtyObj ? { id: specialtyObj.id, name: specialtyObj.get("name") } : null,
        featured: !!obj.get("featured"),
      },
      specialtySortOrder: specialtyObj ? specialtyObj.get("sortOrder") ?? 0 : Number.MAX_SAFE_INTEGER,
    };
  });

  // Array.prototype.sort is stable, so ties keep the query's own sortOrder/name ordering.
  withSortKey.sort((a, b) => a.specialtySortOrder - b.specialtySortOrder);
  return withSortKey.map(({ item }) => item);
}

module.exports = { listCaseTypes, fetchCaseTypeObjects };
