// Server-side subscription entitlement + complimentary-first-case allowance — the only
// source of truth for whether a user may generate a NEW case (see cloud/main.js's
// generateScrubPrep). Pimp Me and Rapid Fire are deliberately NOT gated here: they only
// ever operate on a `prep` the client already holds in memory, so a previously generated
// case (complimentary or not) keeps its Pimp Me/Rapid Fire access forever, even after a
// subscription lapses — that requirement falls out of the existing architecture for free.
//
// One Parse class backs this (see scripts/setup-subscription-schema.js for CLPs):
// `UserEntitlement`, one row per user, holding both the verified subscription state and
// a plain `hasUsedComplimentaryCase` boolean. It's Master-Key-only (no client access at
// all), which is why the flag lives here rather than as a field on `_User` — this app's
// `_User` CLP intentionally allows authenticated self-update (required for signup/login),
// so a client-writable boolean there could be reset via the SDK directly.
//
// The flag is deliberately NOT protected by a reservation/idempotency-key system: a
// genuinely concurrent double-tap can, at worst, trigger two OpenAI calls before
// `saveCase` sets the flag — but it can never result in more than one saved complimentary
// case, since the flag only ever transitions false -> true and is only ever set (never
// read-and-incremented) after a case is durably saved. That's judged the right amount of
// protection for a low-price subscription product; a stricter (and more complex)
// reservation-based design was considered and intentionally dropped in favor of this.
//
// A beforeSave guard (registerBeforeSaveGuards, called once from main.js) rejects a
// second CREATE of UserEntitlement for an owner that already has one — an
// application-level uniqueness guard, not a database-enforced one (Parse Server's public
// schema API doesn't reliably expose a way to declare a true unique index from Cloud
// Code). This only matters for the vanishingly rare case of two concurrent *first-ever*
// calls for the same brand-new user; getOrCreateUserEntitlement already handles losing
// that race gracefully.

class SubscriptionRequiredError extends Error {
  constructor(message) {
    super(message || "A subscription is required to prepare another case.");
    this.name = "SubscriptionRequiredError";
  }
}

function registerBeforeSaveGuards() {
  Parse.Cloud.beforeSave("UserEntitlement", async (request) => {
    if (request.object.existed()) return;
    const query = new Parse.Query("UserEntitlement");
    query.equalTo("owner", request.object.get("owner"));
    const existing = await query.first({ useMasterKey: true });
    if (existing) {
      throw new Parse.Error(Parse.Error.DUPLICATE_VALUE, "A UserEntitlement row already exists for this user.");
    }
  });
}

async function fetchUserEntitlement(owner) {
  const query = new Parse.Query("UserEntitlement");
  query.equalTo("owner", owner);
  return query.first({ useMasterKey: true });
}

/** @param {{ fetchUserEntitlement?: typeof fetchUserEntitlement, now?: () => Date }} [deps] */
async function getOrCreateUserEntitlement(owner, deps = {}) {
  const fetch = deps.fetchUserEntitlement || fetchUserEntitlement;
  const now = deps.now || (() => new Date());
  let entitlement = await fetch(owner);
  if (entitlement) return entitlement;

  const UserEntitlementClass = Parse.Object.extend("UserEntitlement");
  entitlement = new UserEntitlementClass();
  entitlement.set("owner", owner);
  entitlement.set("appAccountToken", require("crypto").randomUUID());
  entitlement.set("subscriptionStatus", "none");
  entitlement.set("hasUsedComplimentaryCase", false);
  entitlement.set("createdAtVerified", now());
  try {
    await entitlement.save(null, { useMasterKey: true });
  } catch (err) {
    // Lost a rare race with a concurrent first-ever call for this owner — the winner's
    // row is the canonical one; use it instead.
    if (err.code !== Parse.Error.DUPLICATE_VALUE) throw err;
    entitlement = await fetch(owner);
  }
  return entitlement;
}

function isEntitlementActive(entitlement) {
  const status = entitlement.get("subscriptionStatus");
  return status === "active" || status === "grace_period";
}

/** Never computed from local date math — always the verified Apple-signed fields. */
function deriveSubscriptionStatus({ now, expiresAt, revokedAt, gracePeriodExpiresAt, isInBillingRetryPeriod }) {
  if (revokedAt && revokedAt <= now) return "revoked";
  if (gracePeriodExpiresAt && gracePeriodExpiresAt > now) return "grace_period";
  if (expiresAt && expiresAt > now) return "active";
  if (isInBillingRetryPeriod) return "billing_retry";
  return "expired";
}

/**
 * Applies a verified (already signature-checked) transaction — and optional renewal info
 * — to the owning user's UserEntitlement row. Ignores a transaction whose
 * `appAccountToken` doesn't match this user's own stored token (a purchase legitimately
 * made under a different Scrub Prep account) and ignores stale/out-of-order data (only
 * ever moves forward in time, per the transaction's own Apple-signed `signedDate` — never
 * regresses state from a delayed/duplicate/retried notification).
 *
 * @param {{ owner: Parse.User, decodedTransaction: object, decodedRenewalInfo?: object|null }} params
 * @param {{ now?: () => Date }} [deps]
 */
async function applyVerifiedTransaction({ owner, decodedTransaction, decodedRenewalInfo }, deps = {}) {
  const entitlement = await getOrCreateUserEntitlement(owner, deps);
  const now = (deps.now || (() => new Date()))();

  if (
    decodedTransaction.appAccountToken &&
    entitlement.get("appAccountToken") &&
    decodedTransaction.appAccountToken !== entitlement.get("appAccountToken")
  ) {
    return { entitlement, applied: false, reason: "appAccountTokenMismatch" };
  }

  const incomingSignedDate = decodedTransaction.signedDate || 0;
  const lastSignedDate = entitlement.get("subscriptionLastSignedDate") || 0;
  if (incomingSignedDate < lastSignedDate) {
    return { entitlement, applied: false, reason: "staleData" };
  }

  const expiresAt = decodedTransaction.expiresDate ? new Date(decodedTransaction.expiresDate) : null;
  const revokedAt = decodedTransaction.revocationDate ? new Date(decodedTransaction.revocationDate) : null;
  const gracePeriodExpiresAt =
    decodedRenewalInfo && decodedRenewalInfo.gracePeriodExpiresDate
      ? new Date(decodedRenewalInfo.gracePeriodExpiresDate)
      : null;
  const isInBillingRetryPeriod = !!(decodedRenewalInfo && decodedRenewalInfo.isInBillingRetryPeriod);
  const status = deriveSubscriptionStatus({ now, expiresAt, revokedAt, gracePeriodExpiresAt, isInBillingRetryPeriod });

  entitlement.set("subscriptionStatus", status);
  entitlement.set("subscriptionProductId", decodedTransaction.productId || null);
  entitlement.set("subscriptionExpiresAt", expiresAt);
  entitlement.set("subscriptionGracePeriodExpiresAt", gracePeriodExpiresAt);
  entitlement.set("subscriptionRevokedAt", revokedAt);
  if (decodedRenewalInfo) {
    entitlement.set("subscriptionAutoRenewStatus", decodedRenewalInfo.autoRenewStatus === 1);
    entitlement.set("subscriptionAutoRenewProductId", decodedRenewalInfo.autoRenewProductId || null);
  }
  entitlement.set("subscriptionOriginalTransactionId", decodedTransaction.originalTransactionId || null);
  entitlement.set("subscriptionLastSignedDate", incomingSignedDate);
  entitlement.set("lastVerifiedAt", now);
  await entitlement.save(null, { useMasterKey: true });
  return { entitlement, applied: true };
}

function toIso(date) {
  return date ? date.toISOString() : null;
}

/**
 * @param {Parse.User} owner
 * @param {object} [deps]
 */
async function getAccessStatus(owner, deps = {}) {
  const entitlement = await getOrCreateUserEntitlement(owner, deps);
  const hasUsedComplimentaryCase = !!entitlement.get("hasUsedComplimentaryCase");
  const active = isEntitlementActive(entitlement);
  const statusLabel = entitlement.get("subscriptionStatus") || "none";

  return {
    appAccountToken: entitlement.get("appAccountToken"),
    canGenerateNewCase: active || !hasUsedComplimentaryCase,
    hasUsedComplimentaryCase,
    subscription: {
      isActive: active,
      status: statusLabel,
      productId: entitlement.get("subscriptionProductId") || null,
      expiresAt: toIso(entitlement.get("subscriptionExpiresAt")),
      accessEndsAt: toIso(
        statusLabel === "grace_period"
          ? entitlement.get("subscriptionGracePeriodExpiresAt")
          : entitlement.get("subscriptionExpiresAt")
      ),
      autoRenewStatus: entitlement.get("subscriptionAutoRenewStatus") ?? null,
      autoRenewProductId: entitlement.get("subscriptionAutoRenewProductId") || null,
    },
  };
}

/**
 * The access decision for generateScrubPrep. Returns normally (nothing to check-in) when
 * the caller may generate; throws SubscriptionRequiredError (the client shows the
 * paywall) otherwise.
 *
 * @param {Parse.User} owner
 * @param {{ fetchUserEntitlement?, now?: () => Date }} [deps]
 */
async function checkAccess(owner, deps = {}) {
  const entitlement = await getOrCreateUserEntitlement(owner, deps);
  if (isEntitlementActive(entitlement)) return;
  if (entitlement.get("hasUsedComplimentaryCase")) {
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
async function markComplimentaryCaseUsed(owner, deps = {}) {
  const entitlement = await getOrCreateUserEntitlement(owner, deps);
  if (entitlement.get("hasUsedComplimentaryCase")) return;
  entitlement.set("hasUsedComplimentaryCase", true);
  await entitlement.save(null, { useMasterKey: true });
}

module.exports = {
  SubscriptionRequiredError,
  registerBeforeSaveGuards,
  getOrCreateUserEntitlement,
  isEntitlementActive,
  deriveSubscriptionStatus,
  applyVerifiedTransaction,
  getAccessStatus,
  checkAccess,
  markComplimentaryCaseUsed,
  fetchUserEntitlement,
};
