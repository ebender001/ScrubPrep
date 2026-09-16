// Server-side subscription entitlement + complimentary-first-case allowance — the only
// source of truth for whether a user may generate a NEW case (see cloud/main.js's
// generateScrubPrep). Pimp Me and Rapid Fire are deliberately NOT gated here: they only
// ever operate on a `prep` the client already holds in memory, so a previously generated
// case (complimentary or not) keeps its Pimp Me/Rapid Fire access forever, even after a
// subscription lapses — that requirement falls out of the existing architecture for free.
//
// Two Parse classes back this (see scripts/setup-subscription-schema.js for CLPs):
//   UserEntitlement          — one row per user; the verified subscription state.
//   ComplimentaryReservation — at most one row per user; enforces "exactly one free case."
// Both classes have a beforeSave guard (registerBeforeSaveGuards, called once from
// main.js) that rejects a second CREATE for an owner that already has a row — an
// application-level uniqueness guard, not a database-enforced one (Parse Server's public
// schema API doesn't reliably expose a way to declare a true unique index from Cloud
// Code). This closes the race for all but two requests landing within the same few
// milliseconds; consumeReservation() below has a second, final check as defense in depth.

const STALE_RESERVATION_MS = 2 * 60 * 1000; // generous for a full OpenAI round trip

class SubscriptionRequiredError extends Error {
  constructor(message) {
    super(message || "A subscription is required to prepare another case.");
    this.name = "SubscriptionRequiredError";
  }
}

class ReservationInProgressError extends Error {
  constructor(message) {
    super(message || "Your complimentary case is still being prepared. Please wait a moment and try again.");
    this.name = "ReservationInProgressError";
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

  Parse.Cloud.beforeSave("ComplimentaryReservation", async (request) => {
    if (request.object.existed()) return;
    const query = new Parse.Query("ComplimentaryReservation");
    query.equalTo("owner", request.object.get("owner"));
    const existing = await query.first({ useMasterKey: true });
    if (existing) {
      throw new Parse.Error(Parse.Error.DUPLICATE_VALUE, "A complimentary reservation already exists for this user.");
    }
  });
}

// MARK: - UserEntitlement

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
 * @param {{ pendingIdempotencyKey?: string }} [options]
 * @param {object} [deps]
 */
async function getAccessStatus(owner, { pendingIdempotencyKey } = {}, deps = {}) {
  const entitlement = await getOrCreateUserEntitlement(owner, deps);

  let pendingReservationResolved = false;
  if (pendingIdempotencyKey) {
    pendingReservationResolved = await reconcileStaleReservation(owner, pendingIdempotencyKey, deps);
  }

  const hasConsumedComplimentary = await hasConsumedComplimentaryCase(owner, deps);
  const active = isEntitlementActive(entitlement);
  const statusLabel = entitlement.get("subscriptionStatus") || "none";

  return {
    appAccountToken: entitlement.get("appAccountToken"),
    canGenerateNewCase: active || !hasConsumedComplimentary,
    hasUsedComplimentaryCase: hasConsumedComplimentary,
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
    pendingReservationResolved,
  };
}

// MARK: - ComplimentaryReservation

async function fetchReservation(owner) {
  const query = new Parse.Query("ComplimentaryReservation");
  query.equalTo("owner", owner);
  return query.first({ useMasterKey: true });
}

async function hasConsumedComplimentaryCase(owner, deps = {}) {
  const fetch = deps.fetchReservation || fetchReservation;
  const existing = await fetch(owner);
  return !!existing && existing.get("status") === "consumed";
}

function isStale(reservation, now) {
  const reservedAt = reservation.get("reservedAt");
  if (!reservedAt) return true;
  return now.getTime() - reservedAt.getTime() > STALE_RESERVATION_MS;
}

async function createReservation(owner, requestToken, now) {
  const ReservationClass = Parse.Object.extend("ComplimentaryReservation");
  const reservation = new ReservationClass();
  reservation.set("owner", owner);
  reservation.set("status", "reserved");
  reservation.set("requestToken", requestToken);
  reservation.set("reservedAt", now);
  try {
    await reservation.save(null, { useMasterKey: true });
    return reservation;
  } catch (err) {
    if (err.code !== Parse.Error.DUPLICATE_VALUE) throw err;
    return null; // lost the race — caller re-fetches the winner
  }
}

/**
 * The core access decision for generateScrubPrep. Returns `{ mode: "subscribed" }` or
 * `{ mode: "complimentary", reservation }`; throws SubscriptionRequiredError (paywall) or
 * ReservationInProgressError (a genuinely concurrent duplicate request).
 *
 * @param {Parse.User} owner
 * @param {string} idempotencyKey
 * @param {{ fetchUserEntitlement?, fetchReservation?, now?: () => Date }} [deps]
 */
async function checkAccessAndReserve(owner, idempotencyKey, deps = {}) {
  const now = (deps.now || (() => new Date()))();
  const entitlement = await getOrCreateUserEntitlement(owner, deps);
  if (isEntitlementActive(entitlement)) {
    return { mode: "subscribed" };
  }

  const fetch = deps.fetchReservation || fetchReservation;
  let existing = await fetch(owner);

  if (!existing) {
    const created = await createReservation(owner, idempotencyKey, now);
    if (created) {
      return { mode: "complimentary", reservation: created };
    }
    existing = await fetch(owner);
    if (!existing) {
      // Shouldn't happen (the create that beat us must have landed), but fail closed.
      throw new ReservationInProgressError();
    }
  }

  if (existing.get("status") === "consumed") {
    throw new SubscriptionRequiredError();
  }
  if (existing.get("requestToken") === idempotencyKey) {
    return { mode: "complimentary", reservation: existing };
  }
  if (isStale(existing, now)) {
    existing.set("requestToken", idempotencyKey);
    existing.set("reservedAt", now);
    await existing.save(null, { useMasterKey: true });
    return { mode: "complimentary", reservation: existing };
  }
  throw new ReservationInProgressError();
}

/**
 * Marks a reservation consumed after its case has been successfully saved. Re-checks for
 * a concurrently-consumed sibling row (see the module doc comment's "defense in depth")
 * before writing — the exceedingly rare loser just gets cleaned up instead of double-
 * marking, and the case it produced is still kept rather than discarded.
 */
async function consumeReservation(reservation, caseId) {
  const query = new Parse.Query("ComplimentaryReservation");
  query.equalTo("owner", reservation.get("owner"));
  query.equalTo("status", "consumed");
  const alreadyConsumed = await query.first({ useMasterKey: true });
  if (alreadyConsumed && alreadyConsumed.id !== reservation.id) {
    await reservation.destroy({ useMasterKey: true });
    return;
  }
  reservation.set("status", "consumed");
  reservation.set("caseId", caseId);
  await reservation.save(null, { useMasterKey: true });
}

/** A failed generation must never consume eligibility — delete the reservation outright. */
async function releaseReservation(reservation) {
  await reservation.destroy({ useMasterKey: true });
}

/**
 * Called from getAccessStatus when the client passes the idempotency key of a request it
 * couldn't confirm the outcome of. Releases a matching reservation if it's stale
 * (abandoned) so a genuine retry isn't blocked as "already in progress" forever.
 */
async function reconcileStaleReservation(owner, pendingIdempotencyKey, deps = {}) {
  const fetch = deps.fetchReservation || fetchReservation;
  const now = (deps.now || (() => new Date()))();
  const existing = await fetch(owner);
  if (!existing) return false;
  if (existing.get("requestToken") !== pendingIdempotencyKey) return false;
  if (existing.get("status") === "consumed") return false;
  if (!isStale(existing, now)) return false;
  await releaseReservation(existing);
  return true;
}

module.exports = {
  SubscriptionRequiredError,
  ReservationInProgressError,
  registerBeforeSaveGuards,
  getOrCreateUserEntitlement,
  isEntitlementActive,
  deriveSubscriptionStatus,
  applyVerifiedTransaction,
  getAccessStatus,
  checkAccessAndReserve,
  consumeReservation,
  releaseReservation,
  reconcileStaleReservation,
  fetchUserEntitlement,
  fetchReservation,
  STALE_RESERVATION_MS,
};
