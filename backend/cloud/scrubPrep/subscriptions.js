// Tracks whether a user has used their one complimentary (non-subscription) case — the
// only backend-side subscription-adjacent state in this app. Whether a subscription is
// currently active is determined entirely on-device via StoreKit 2
// (see SubscriptionManager.swift) and is never reported to or verified by this backend —
// see README.md's "Subscriptions" section for the reasoning and the accepted tradeoff
// (a modified client could in principle skip its own paywall check; there is no
// server-side enforcement of an ongoing subscription requirement).
//
// hasUsedComplimentaryCase lives directly on `_User` (see
// scripts/setup-user-subscription-fields.js) rather than a separate Parse class — there's
// nothing to look up or create, since `request.user` always already exists.
// registerProtectedFieldsGuard (called once from main.js) installs a beforeSave trigger on
// `_User` that rejects any non-Master-Key write touching this field, so a signed-in user's
// normal ability to update their own `_User` row (e.g. changing their email) can't be used
// to reset their own complimentary-case flag.

const PROTECTED_USER_FIELDS = ["hasUsedComplimentaryCase"];

function registerProtectedFieldsGuard() {
  Parse.Cloud.beforeSave("_User", (request) => {
    if (request.master) return;
    // A brand-new _User being created (signup) reports every field as "dirty",
    // including ones the client never touched — only enforce this on an UPDATE to an
    // already-existing user, where "dirty" correctly means "this save is trying to
    // change it."
    if (!request.object.existed()) return;
    for (const field of PROTECTED_USER_FIELDS) {
      if (request.object.dirty(field)) {
        throw new Parse.Error(Parse.Error.OPERATION_FORBIDDEN, `${field} cannot be modified directly.`);
      }
    }
  });
}

/**
 * Called from saveCase after a case has been durably saved — marks the complimentary
 * case used (idempotent: a no-op if already true). This is the ONLY place the flag is
 * ever set, and it's unconditional (not gated on current subscription status): "the
 * first case ever" is what's complimentary, whether or not the user happened to already
 * be subscribed when they generated it.
 *
 * @param {Parse.User} user
 */
async function markComplimentaryCaseUsed(user) {
  if (user.get("hasUsedComplimentaryCase")) return;
  user.set("hasUsedComplimentaryCase", true);
  await user.save(null, { useMasterKey: true });
}

module.exports = {
  registerProtectedFieldsGuard,
  markComplimentaryCaseUsed,
  PROTECTED_USER_FIELDS,
};
