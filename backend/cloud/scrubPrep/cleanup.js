// Periodic maintenance for the ephemeral PimpSession scratchpad (see cloud/main.js) —
// a session is meant to be completed within minutes, so any row not updated in a while
// is almost certainly abandoned (the student closed the app mid-session, or it finished
// and its data now lives separately as a persisted PimpMeSession). Nothing ever reads a
// PimpSession row again once it's stale, so it's safe to delete outright.

const DEFAULT_MAX_AGE_DAYS = 1;

async function fetchStaleSessionsBatch(cutoff) {
  const query = new Parse.Query("PimpSession");
  query.lessThan("updatedAt", cutoff);
  query.limit(1000);
  return query.find({ useMasterKey: true });
}

async function destroyBatch(objects) {
  return Parse.Object.destroyAll(objects, { useMasterKey: true });
}

/**
 * Deletes every PimpSession row last updated before `maxAgeDays` ago, a batch at a time
 * (re-querying after each delete rather than paging, since the matched rows are gone).
 *
 * @param {{ maxAgeDays?: number }} params
 * @param {{ fetchStaleSessionsBatch?: typeof fetchStaleSessionsBatch, destroyBatch?: typeof destroyBatch, now?: () => Date }} [deps]
 * @returns {Promise<number>} total rows deleted
 */
async function cleanupOldPimpSessions({ maxAgeDays } = {}, deps = {}) {
  const fetchBatch = deps.fetchStaleSessionsBatch || fetchStaleSessionsBatch;
  const destroy = deps.destroyBatch || destroyBatch;
  const now = deps.now || (() => new Date());
  const days = typeof maxAgeDays === "number" && maxAgeDays > 0 ? maxAgeDays : DEFAULT_MAX_AGE_DAYS;
  const cutoff = new Date(now().getTime() - days * 24 * 60 * 60 * 1000);

  let totalDeleted = 0;
  let batch = await fetchBatch(cutoff);
  while (batch.length > 0) {
    await destroy(batch);
    totalDeleted += batch.length;
    batch = await fetchBatch(cutoff);
  }
  return totalDeleted;
}

module.exports = { cleanupOldPimpSessions, fetchStaleSessionsBatch, destroyBatch, DEFAULT_MAX_AGE_DAYS };
