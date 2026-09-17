const { test } = require("node:test");
const assert = require("node:assert/strict");
const subscriptions = require("../cloud/scrubPrep/subscriptions");

function fakeUser(attrs = {}) {
  const state = { hasUsedComplimentaryCase: false, ...attrs };
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
