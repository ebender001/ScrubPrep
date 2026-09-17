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
  const user = fakeUser({ appAccountToken: "already-has-a-token" });
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

test("getAccessStatus: active subscriber can always generate, regardless of complimentary status", async () => {
  const user = fakeUser({ subscriptionStatus: "active", hasUsedComplimentaryCase: true, subscriptionProductId: "p" });
  const status = await subscriptions.getAccessStatus(user);
  assert.equal(status.canGenerateNewCase, true);
  assert.equal(status.subscription.isActive, true);
});

test("getAccessStatus: non-subscriber who hasn't used the complimentary case can generate", async () => {
  const status = await subscriptions.getAccessStatus(fakeUser());
  assert.equal(status.canGenerateNewCase, true);
  assert.equal(status.hasUsedComplimentaryCase, false);
});

test("getAccessStatus: non-subscriber who has used the complimentary case cannot generate", async () => {
  const status = await subscriptions.getAccessStatus(fakeUser({ hasUsedComplimentaryCase: true }));
  assert.equal(status.canGenerateNewCase, false);
});

test("getAccessStatus: accessEndsAt reflects the grace-period date while in grace, else plain expiry", async () => {
  const graceExpiry = new Date("2026-04-01T00:00:00Z");
  const plainExpiry = new Date("2026-03-15T00:00:00Z");
  const inGrace = await subscriptions.getAccessStatus(
    fakeUser({
      subscriptionStatus: "grace_period",
      subscriptionExpiresAt: plainExpiry,
      subscriptionGracePeriodExpiresAt: graceExpiry,
    })
  );
  assert.equal(inGrace.subscription.accessEndsAt, graceExpiry.toISOString());

  const active = await subscriptions.getAccessStatus(
    fakeUser({ subscriptionStatus: "active", subscriptionExpiresAt: plainExpiry })
  );
  assert.equal(active.subscription.accessEndsAt, plainExpiry.toISOString());
});

test("getAccessStatus generates and persists an appAccountToken the first time it's needed", async () => {
  const user = fakeUser();
  const status = await subscriptions.getAccessStatus(user);
  assert.ok(status.appAccountToken, "should generate a token");
  assert.equal(user.get("appAccountToken"), status.appAccountToken);
  assert.deepEqual(user._saveCalls, [{ useMasterKey: true }]);
});

test("getAccessStatus reuses an existing appAccountToken without saving again", async () => {
  const user = fakeUser({ appAccountToken: "existing-token" });
  const status = await subscriptions.getAccessStatus(user);
  assert.equal(status.appAccountToken, "existing-token");
  assert.equal(user._saveCalls.length, 0);
});

test("applyReportedSubscriptionStatus ignores a report whose appAccountToken belongs to a different user", async () => {
  const user = fakeUser({ appAccountToken: "my-token" });
  const result = await subscriptions.applyReportedSubscriptionStatus(user, {
    status: "active",
    appAccountToken: "someone-elses-token",
  });
  assert.equal(result.applied, false);
  assert.equal(result.reason, "appAccountTokenMismatch");
  assert.equal(user.get("subscriptionStatus"), "none", "must not have been overwritten");
  assert.equal(user._saveCalls.length, 0);
});

test("applyReportedSubscriptionStatus applies a report whose appAccountToken matches", async () => {
  const user = fakeUser({ appAccountToken: "my-token" });
  const result = await subscriptions.applyReportedSubscriptionStatus(user, {
    status: "active",
    appAccountToken: "my-token",
  });
  assert.equal(result.applied, true);
  assert.equal(user.get("subscriptionStatus"), "active");
});

test("applyReportedSubscriptionStatus ensures the user's own token exists before comparing, rather than assuming a prior getAccessStatus call already created one", async () => {
  // A user who has genuinely never fetched a token yet must still be protected — the
  // check must not silently pass just because nothing was on record beforehand.
  const freshUser = fakeUser();
  const result = await subscriptions.applyReportedSubscriptionStatus(freshUser, {
    status: "active",
    appAccountToken: "someone-elses-token",
  });
  assert.equal(result.applied, false);
  assert.equal(result.reason, "appAccountTokenMismatch");
  assert.ok(freshUser.get("appAccountToken"), "a token should have been generated for comparison");
  assert.notEqual(freshUser.get("appAccountToken"), "someone-elses-token");
});

test("applyReportedSubscriptionStatus applies leniently when the report itself carries no token at all", async () => {
  const userWithToken = fakeUser({ appAccountToken: "my-token" });
  const result = await subscriptions.applyReportedSubscriptionStatus(userWithToken, { status: "active" });
  assert.equal(result.applied, true);
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
