const { test } = require("node:test");
const assert = require("node:assert/strict");
const subscriptions = require("../cloud/scrubPrep/subscriptions");

function fakeOwner(id) {
  return { id };
}

function fakeEntitlement(attrs) {
  const state = { subscriptionStatus: "none", appAccountToken: "token-owner", ...attrs };
  return {
    id: state.id || "entitlement1",
    get: (key) => state[key],
    set: (key, value) => {
      state[key] = value;
    },
    save: async function () {
      return this;
    },
    _state: state,
  };
}

test("deriveSubscriptionStatus: revoked wins over everything else", () => {
  const now = new Date("2026-01-15T00:00:00Z");
  const status = subscriptions.deriveSubscriptionStatus({
    now,
    expiresAt: new Date("2026-02-01T00:00:00Z"), // still in the future
    revokedAt: new Date("2026-01-10T00:00:00Z"), // but revoked
    gracePeriodExpiresAt: null,
    isInBillingRetryPeriod: false,
  });
  assert.equal(status, "revoked");
});

test("deriveSubscriptionStatus: active grace period counts as access even if expiresDate has passed", () => {
  const now = new Date("2026-01-15T00:00:00Z");
  const status = subscriptions.deriveSubscriptionStatus({
    now,
    expiresAt: new Date("2026-01-10T00:00:00Z"), // already past
    revokedAt: null,
    gracePeriodExpiresAt: new Date("2026-01-20T00:00:00Z"), // grace extends past now
    isInBillingRetryPeriod: false,
  });
  assert.equal(status, "grace_period");
});

test("deriveSubscriptionStatus: active when expiresDate is in the future", () => {
  const now = new Date("2026-01-15T00:00:00Z");
  const status = subscriptions.deriveSubscriptionStatus({
    now,
    expiresAt: new Date("2026-02-01T00:00:00Z"),
    revokedAt: null,
    gracePeriodExpiresAt: null,
    isInBillingRetryPeriod: false,
  });
  assert.equal(status, "active");
});

test("deriveSubscriptionStatus: billing_retry when expired but Apple is still retrying", () => {
  const now = new Date("2026-01-15T00:00:00Z");
  const status = subscriptions.deriveSubscriptionStatus({
    now,
    expiresAt: new Date("2026-01-10T00:00:00Z"),
    revokedAt: null,
    gracePeriodExpiresAt: null,
    isInBillingRetryPeriod: true,
  });
  assert.equal(status, "billing_retry");
});

test("deriveSubscriptionStatus: expired when nothing else applies", () => {
  const now = new Date("2026-01-15T00:00:00Z");
  const status = subscriptions.deriveSubscriptionStatus({
    now,
    expiresAt: new Date("2026-01-10T00:00:00Z"),
    revokedAt: null,
    gracePeriodExpiresAt: null,
    isInBillingRetryPeriod: false,
  });
  assert.equal(status, "expired");
});

test("isEntitlementActive is true for active and grace_period, false otherwise", () => {
  assert.equal(subscriptions.isEntitlementActive(fakeEntitlement({ subscriptionStatus: "active" })), true);
  assert.equal(subscriptions.isEntitlementActive(fakeEntitlement({ subscriptionStatus: "grace_period" })), true);
  for (const status of ["none", "expired", "revoked", "billing_retry"]) {
    assert.equal(subscriptions.isEntitlementActive(fakeEntitlement({ subscriptionStatus: status })), false, status);
  }
});

test("applyVerifiedTransaction ignores a transaction whose appAccountToken belongs to a different Scrub Prep account", async () => {
  const entitlement = fakeEntitlement({ appAccountToken: "owner-token" });
  const owner = fakeOwner("u1");
  const result = await subscriptions.applyVerifiedTransaction(
    {
      owner,
      decodedTransaction: {
        appAccountToken: "someone-elses-token",
        expiresDate: Date.now() + 100000,
        signedDate: Date.now(),
        productId: "dev.benderapps.ScrubPrep.subscription.monthly",
      },
    },
    { fetchUserEntitlement: async () => entitlement }
  );
  assert.equal(result.applied, false);
  assert.equal(result.reason, "appAccountTokenMismatch");
  assert.equal(entitlement.get("subscriptionStatus"), "none", "must not have been overwritten");
});

test("applyVerifiedTransaction ignores stale/out-of-order data older than what's already stored", async () => {
  const entitlement = fakeEntitlement({
    appAccountToken: "owner-token",
    subscriptionStatus: "active",
    subscriptionLastSignedDate: 2000,
  });
  const owner = fakeOwner("u1");
  const result = await subscriptions.applyVerifiedTransaction(
    {
      owner,
      decodedTransaction: {
        appAccountToken: "owner-token",
        expiresDate: Date.now() - 1000000, // would look "expired" if applied
        signedDate: 1000, // older than the entitlement's last-applied signedDate
        productId: "dev.benderapps.ScrubPrep.subscription.monthly",
      },
    },
    { fetchUserEntitlement: async () => entitlement }
  );
  assert.equal(result.applied, false);
  assert.equal(result.reason, "staleData");
  assert.equal(entitlement.get("subscriptionStatus"), "active", "must not have regressed");
});

test("applyVerifiedTransaction applies a newer, matching transaction and updates status/expiry", async () => {
  const entitlement = fakeEntitlement({ appAccountToken: "owner-token", subscriptionLastSignedDate: 1000 });
  const owner = fakeOwner("u1");
  const futureExpiry = Date.now() + 1000000;
  const result = await subscriptions.applyVerifiedTransaction(
    {
      owner,
      decodedTransaction: {
        appAccountToken: "owner-token",
        expiresDate: futureExpiry,
        signedDate: 2000,
        productId: "dev.benderapps.ScrubPrep.subscription.quarterly",
        originalTransactionId: "orig123",
      },
    },
    { fetchUserEntitlement: async () => entitlement }
  );
  assert.equal(result.applied, true);
  assert.equal(entitlement.get("subscriptionStatus"), "active");
  assert.equal(entitlement.get("subscriptionProductId"), "dev.benderapps.ScrubPrep.subscription.quarterly");
  assert.equal(entitlement.get("subscriptionExpiresAt").getTime(), futureExpiry);
  assert.equal(entitlement.get("subscriptionOriginalTransactionId"), "orig123");
});

test("applyVerifiedTransaction applies grace-period renewal info alongside the transaction", async () => {
  const entitlement = fakeEntitlement({ appAccountToken: "owner-token" });
  const owner = fakeOwner("u1");
  const graceExpiry = Date.now() + 500000;
  await subscriptions.applyVerifiedTransaction(
    {
      owner,
      decodedTransaction: {
        appAccountToken: "owner-token",
        expiresDate: Date.now() - 1000, // just past — would be "expired" without grace
        signedDate: 5000,
        productId: "dev.benderapps.ScrubPrep.subscription.monthly",
      },
      decodedRenewalInfo: {
        gracePeriodExpiresDate: graceExpiry,
        autoRenewStatus: 1,
        autoRenewProductId: "dev.benderapps.ScrubPrep.subscription.monthly",
        isInBillingRetryPeriod: true,
      },
    },
    { fetchUserEntitlement: async () => entitlement }
  );
  assert.equal(entitlement.get("subscriptionStatus"), "grace_period");
  assert.equal(entitlement.get("subscriptionAutoRenewStatus"), true);
});
