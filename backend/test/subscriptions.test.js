const { test } = require("node:test");
const assert = require("node:assert/strict");
const subscriptions = require("../cloud/scrubPrep/subscriptions");

function fakeUser(attrs = {}) {
  const state = { subscriptionStatus: "none", hasUsedComplimentaryCase: false, ...attrs };
  const saveCalls = [];
  return {
    get: (key) => state[key],
    set: (key, value) => {
      state[key] = value;
    },
    save: async function (_data, options) {
      saveCalls.push(options);
      return this;
    },
    _state: state,
    _saveCalls: saveCalls,
  };
}

test("isEntitlementActive is true for active and grace_period, false otherwise", () => {
  assert.equal(subscriptions.isEntitlementActive(fakeUser({ subscriptionStatus: "active" })), true);
  assert.equal(subscriptions.isEntitlementActive(fakeUser({ subscriptionStatus: "grace_period" })), true);
  for (const status of ["none", "expired", "revoked", "billing_retry"]) {
    assert.equal(subscriptions.isEntitlementActive(fakeUser({ subscriptionStatus: status })), false, status);
  }
});

test("checkAccess allows an active subscriber regardless of complimentary status", () => {
  const user = fakeUser({ subscriptionStatus: "active", hasUsedComplimentaryCase: true });
  assert.doesNotThrow(() => subscriptions.checkAccess(user));
});

test("checkAccess allows a non-subscriber who hasn't used their complimentary case", () => {
  const user = fakeUser({ subscriptionStatus: "none", hasUsedComplimentaryCase: false });
  assert.doesNotThrow(() => subscriptions.checkAccess(user));
});

test("checkAccess throws SubscriptionRequiredError for a non-subscriber who already used it", () => {
  const user = fakeUser({ subscriptionStatus: "expired", hasUsedComplimentaryCase: true });
  assert.throws(() => subscriptions.checkAccess(user), subscriptions.SubscriptionRequiredError);
});

test("markComplimentaryCaseUsed sets the flag and saves via the Master Key", async () => {
  const user = fakeUser();
  await subscriptions.markComplimentaryCaseUsed(user);
  assert.equal(user.get("hasUsedComplimentaryCase"), true);
  assert.deepEqual(user._saveCalls, [{ useMasterKey: true }]);
});

test("markComplimentaryCaseUsed is a no-op (no extra save) if already used", async () => {
  const user = fakeUser({ hasUsedComplimentaryCase: true });
  await subscriptions.markComplimentaryCaseUsed(user);
  assert.equal(user._saveCalls.length, 0);
});

test("applyReportedSubscriptionStatus stores every reported field and stamps subscriptionLastReportedAt", async () => {
  const user = fakeUser();
  const now = new Date("2026-02-01T00:00:00Z");
  const expiresAt = new Date("2026-03-01T00:00:00Z");
  await subscriptions.applyReportedSubscriptionStatus(
    user,
    {
      status: "active",
      productId: "dev.benderapps.ScrubPrep.subscription.monthly",
      expiresAt,
      gracePeriodExpiresAt: null,
      autoRenewStatus: true,
      autoRenewProductId: "dev.benderapps.ScrubPrep.subscription.monthly",
      originalTransactionId: "orig123",
    },
    { now: () => now }
  );
  assert.equal(user.get("subscriptionStatus"), "active");
  assert.equal(user.get("subscriptionProductId"), "dev.benderapps.ScrubPrep.subscription.monthly");
  assert.equal(user.get("subscriptionExpiresAt"), expiresAt);
  assert.equal(user.get("subscriptionAutoRenewStatus"), true);
  assert.equal(user.get("subscriptionOriginalTransactionId"), "orig123");
  assert.equal(user.get("subscriptionLastReportedAt"), now);
  assert.deepEqual(user._saveCalls, [{ useMasterKey: true }]);
});

test("getAccessStatus: active subscriber can always generate, regardless of complimentary status", () => {
  const user = fakeUser({ subscriptionStatus: "active", hasUsedComplimentaryCase: true, subscriptionProductId: "p" });
  const status = subscriptions.getAccessStatus(user);
  assert.equal(status.canGenerateNewCase, true);
  assert.equal(status.subscription.isActive, true);
});

test("getAccessStatus: non-subscriber who hasn't used the complimentary case can generate", () => {
  const status = subscriptions.getAccessStatus(fakeUser());
  assert.equal(status.canGenerateNewCase, true);
  assert.equal(status.hasUsedComplimentaryCase, false);
});

test("getAccessStatus: non-subscriber who has used the complimentary case cannot generate", () => {
  const status = subscriptions.getAccessStatus(fakeUser({ hasUsedComplimentaryCase: true }));
  assert.equal(status.canGenerateNewCase, false);
});

test("getAccessStatus: accessEndsAt reflects the grace-period date while in grace, else plain expiry", () => {
  const graceExpiry = new Date("2026-04-01T00:00:00Z");
  const plainExpiry = new Date("2026-03-15T00:00:00Z");
  const inGrace = subscriptions.getAccessStatus(
    fakeUser({
      subscriptionStatus: "grace_period",
      subscriptionExpiresAt: plainExpiry,
      subscriptionGracePeriodExpiresAt: graceExpiry,
    })
  );
  assert.equal(inGrace.subscription.accessEndsAt, graceExpiry.toISOString());

  const active = subscriptions.getAccessStatus(
    fakeUser({ subscriptionStatus: "active", subscriptionExpiresAt: plainExpiry })
  );
  assert.equal(active.subscription.accessEndsAt, plainExpiry.toISOString());
});

test("registerProtectedFieldsGuard rejects a non-master write that touches a protected field", async () => {
  const hooks = {};
  const fakeParseCloud = { beforeSave: (name, handler) => { hooks[name] = handler; } };
  const originalCloud = global.Parse && global.Parse.Cloud;
  global.Parse = global.Parse || {};
  global.Parse.Cloud = fakeParseCloud;
  global.Parse.Error = global.Parse.Error || class extends Error {
    constructor(code, message) {
      super(message);
      this.code = code;
    }
  };
  global.Parse.Error.OPERATION_FORBIDDEN = 119;

  subscriptions.registerProtectedFieldsGuard();
  const hook = hooks["_User"];

  const existingDirtyObject = { existed: () => true, dirty: (field) => field === "hasUsedComplimentaryCase" };
  assert.throws(() => hook({ master: false, object: existingDirtyObject }));
  assert.doesNotThrow(() => hook({ master: true, object: existingDirtyObject }));
  assert.doesNotThrow(() => hook({ master: false, object: { existed: () => true, dirty: () => false } }));

  // A brand-new user (signup) reports every field as "dirty" — must never be blocked by
  // this guard, or signup itself would break.
  const newUserObject = { existed: () => false, dirty: () => true };
  assert.doesNotThrow(() => hook({ master: false, object: newUserObject }));

  if (originalCloud) global.Parse.Cloud = originalCloud;
});
