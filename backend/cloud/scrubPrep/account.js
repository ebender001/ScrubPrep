// In-app account deletion (App Store Review Guideline 5.1.1(v)) — removes the signed-in
// user and every row that points back to them. Owner-scoped classes are listed in
// OWNED_CLASSES; `_Session` is keyed by `user` rather than `owner`, so it's handled
// separately. Not touched: PrepCatalog (cross-user cache with no owner — see
// prepCatalog.js) and PimpSession (ephemeral scratchpad with no owner, swept daily by
// cleanup.js's cleanupOldPimpSessions job).
//
// Owned rows are deleted before the user itself, so a failure partway through leaves the
// account intact and the student can simply retry — never a deleted user with orphaned
// data still attached to it.

const OWNED_CLASSES = ["ScrubCase", "PimpMeSession", "AIUsageEvent"];

async function fetchBatch(className, field, user) {
  const query = new Parse.Query(className);
  query.equalTo(field, user);
  query.limit(1000);
  return query.find({ useMasterKey: true });
}

async function destroyBatch(objects) {
  return Parse.Object.destroyAll(objects, { useMasterKey: true });
}

async function destroyUser(user) {
  return user.destroy({ useMasterKey: true });
}

/**
 * Deletes every owned row, every session, then the user. Re-queries after each batch
 * delete rather than paging, same as cleanup.js, since the matched rows are gone.
 *
 * @param {{ user: Parse.User }} params
 * @param {{ fetchBatch?: typeof fetchBatch, destroyBatch?: typeof destroyBatch, destroyUser?: typeof destroyUser }} [deps]
 * @returns {Promise<Record<string, number>>} rows deleted per class
 */
async function deleteAccount({ user }, deps = {}) {
  const fetch = deps.fetchBatch || fetchBatch;
  const destroy = deps.destroyBatch || destroyBatch;
  const removeUser = deps.destroyUser || destroyUser;

  const targets = [
    ...OWNED_CLASSES.map((className) => ({ className, field: "owner" })),
    { className: "_Session", field: "user" },
  ];

  const deletedCounts = {};
  for (const { className, field } of targets) {
    let total = 0;
    let batch = await fetch(className, field, user);
    while (batch.length > 0) {
      await destroy(batch);
      total += batch.length;
      batch = await fetch(className, field, user);
    }
    deletedCounts[className] = total;
  }

  await removeUser(user);
  return deletedCounts;
}

module.exports = { deleteAccount, fetchBatch, destroyBatch, destroyUser, OWNED_CLASSES };
