// Server-side subscription entitlement + complimentary-first-case allowance — the only
// source of truth for whether a user may generate a NEW case (see cloud/main.js's
// generateScrubPrep). Pimp Me and Rapid Fire are deliberately NOT gated here: they only
// ever operate on a `prep` the client already holds in memory, so a previously generated
// case (complimentary or not) keeps its Pimp Me/Rapid Fire access forever, even after a
// subscription lapses — that requirement falls out of the existing architecture for free.
//
// State lives directly on `_User` (fields set in scripts/setup-user-subscription-fields.js),
// not a separate Parse class — simpler, and there's nothing to look up or create, since
// `request.user` always already exists. `registerProtectedFieldsGuard` (called once from
// main.js) installs a beforeSave trigger on `_User` that rejects any non-Master-Key write
// touching these fields, so a signed-in user's normal ability to update their own `_User`
// row (needed for e.g. changing their email) can't be used to reset their own
// `hasUsedComplimentaryCase` flag or subscription state.
//
// Trust model: this app deliberately does NOT independently re-verify Apple's
// cryptographic signature on subscription data server-side. It trusts StoreKit 2's own
// on-device verification (`VerificationResult` — real Apple cryptography, just checked on
// the client rather than re-checked here) and has the client report the already-verified
// transaction's plain fields. This was a deliberate simplification (see the project's
// history/README): independently re-verifying server-side needs a real JWS-verification
// library, Apple's root certificate, and extra plumbing that's disproportionate for a
// low-price subscription product, and isn't what most comparable apps do. The accepted
// tradeoff: a jailbroken device or a tampered client binary could in principle report a
// fabricated "I'm subscribed" status. It CANNOT, however, un-set an already-used
// complimentary flag or otherwise directly write these fields via the normal client SDK —
// that specific path is blocked by the beforeSave guard regardless of this tradeoff.

const PROTECTED_USER_FIELDS = [
  "hasUsedComplimentaryCase",
  "subscriptionStatus",
  "subscriptionProductId",
  "subscriptionExpiresAt",
  "subscriptionGracePeriodExpiresAt",
  "subscriptionAutoRenewStatus",
  "subscriptionAutoRenewProductId",
  "subscriptionOriginalTransactionId",
  "subscriptionLastReportedAt",
];

class SubscriptionRequiredError extends Error {
  constructor(message) {
    super(message || "A subscription is required to prepare another case.");
    this.name = "SubscriptionRequiredError";
  }
}

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

function isEntitlementActive(user) {
  const status = user.get("subscriptionStatus");
  return status === "active" || status === "grace_period";
}

function toIso(date) {
  return date ? date.toISOString() : null;
}

/**
 * Applies a subscription status the client reported after its own StoreKit 2 on-device
 * verification succeeded (see SubscriptionManager.swift) — always overwrites with the
 * latest report (there's no adversarial-ordering concern to guard against once the data
 * is trusted at all; see the file header).
 *
 * @param {Parse.User} user
 * @param {{ productId?: string, status: string, expiresAt?: Date|null, gracePeriodExpiresAt?: Date|null, autoRenewStatus?: boolean|null, autoRenewProductId?: string|null, originalTransactionId?: string|null }} report
 * @param {{ now?: () => Date }} [deps]
 */
async function applyReportedSubscriptionStatus(user, report, deps = {}) {
  const now = (deps.now || (() => new Date()))();
  user.set("subscriptionStatus", report.status || "none");
  user.set("subscriptionProductId", report.productId || null);
  user.set("subscriptionExpiresAt", report.expiresAt || null);
  user.set("subscriptionGracePeriodExpiresAt", report.gracePeriodExpiresAt || null);
  user.set("subscriptionAutoRenewStatus", report.autoRenewStatus ?? null);
  user.set("subscriptionAutoRenewProductId", report.autoRenewProductId || null);
  user.set("subscriptionOriginalTransactionId", report.originalTransactionId || null);
  user.set("subscriptionLastReportedAt", now);
  await user.save(null, { useMasterKey: true });
}

/** @param {Parse.User} user */
function getAccessStatus(user) {
  const hasUsedComplimentaryCase = !!user.get("hasUsedComplimentaryCase");
  const active = isEntitlementActive(user);
  const statusLabel = user.get("subscriptionStatus") || "none";

  return {
    canGenerateNewCase: active || !hasUsedComplimentaryCase,
    hasUsedComplimentaryCase,
    subscription: {
      isActive: active,
      status: statusLabel,
      productId: user.get("subscriptionProductId") || null,
      expiresAt: toIso(user.get("subscriptionExpiresAt")),
      accessEndsAt: toIso(
        statusLabel === "grace_period" ? user.get("subscriptionGracePeriodExpiresAt") : user.get("subscriptionExpiresAt")
      ),
      autoRenewStatus: user.get("subscriptionAutoRenewStatus") ?? null,
      autoRenewProductId: user.get("subscriptionAutoRenewProductId") || null,
    },
  };
}

/**
 * The access decision for generateScrubPrep. Returns normally when the caller may
 * generate; throws SubscriptionRequiredError (the client shows the paywall) otherwise.
 *
 * @param {Parse.User} user
 */
function checkAccess(user) {
  if (isEntitlementActive(user)) return;
  if (user.get("hasUsedComplimentaryCase")) {
    throw new SubscriptionRequiredError();
  }
}

/**
 * Called from saveCase after a case has been durably saved — marks the complimentary
 * case used (idempotent: a no-op if already true). This is the ONLY place the flag is
 * ever set, and it's unconditional (not gated on current subscription status): "the
 * first case ever" is what's complimentary, whether or not the user happened to already
 * be subscribed when they generated it.
 */
async function markComplimentaryCaseUsed(user) {
  if (user.get("hasUsedComplimentaryCase")) return;
  user.set("hasUsedComplimentaryCase", true);
  await user.save(null, { useMasterKey: true });
}

module.exports = {
  SubscriptionRequiredError,
  registerProtectedFieldsGuard,
  isEntitlementActive,
  applyReportedSubscriptionStatus,
  getAccessStatus,
  checkAccess,
  markComplimentaryCaseUsed,
  PROTECTED_USER_FIELDS,
};
