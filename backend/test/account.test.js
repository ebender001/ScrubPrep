const { test } = require("node:test");
const assert = require("node:assert/strict");
const account = require("../cloud/scrubPrep/account");

const user = { id: "user1" };

function fakeRows(count, prefix) {
  return Array.from({ length: count }, (_, i) => ({ id: `${prefix}${i}` }));
}

// Serves each class's rows in the given batches, then [] once exhausted.
function batchedFetch(batchesByClass, calls = []) {
  const remaining = Object.fromEntries(
    Object.entries(batchesByClass).map(([className, batches]) => [className, [...batches]])
  );
  return async (className, field, owner) => {
    calls.push({ className, field, owner });
    return (remaining[className] || []).shift() || [];
  };
}

test("deleteAccount deletes every owned class, sessions, then the user", async () => {
  const events = [];
  const counts = await account.deleteAccount(
    { user },
    {
      fetchBatch: batchedFetch({
        ScrubCase: [fakeRows(2, "c")],
        PimpMeSession: [fakeRows(1, "p")],
        AIUsageEvent: [fakeRows(3, "a"), fakeRows(1, "b")],
        _Session: [fakeRows(1, "s")],
      }),
      destroyBatch: async (objects) => events.push(`destroy:${objects.length}`),
      destroyUser: async (u) => events.push(`user:${u.id}`),
    }
  );

  assert.deepEqual(counts, { ScrubCase: 2, PimpMeSession: 1, AIUsageEvent: 4, _Session: 1 });
  assert.equal(events.at(-1), "user:user1");
});

test("deleteAccount scopes owned classes by owner and sessions by user", async () => {
  const calls = [];
  await account.deleteAccount(
    { user },
    {
      fetchBatch: batchedFetch({}, calls),
      destroyBatch: async () => assert.fail("nothing to destroy"),
      destroyUser: async () => {},
    }
  );

  for (const className of account.OWNED_CLASSES) {
    const call = calls.find((c) => c.className === className);
    assert.equal(call.field, "owner");
    assert.equal(call.owner, user);
  }
  assert.equal(calls.find((c) => c.className === "_Session").field, "user");
});

test("deleteAccount leaves the user in place if deleting owned data fails", async () => {
  let userDestroyed = false;
  await assert.rejects(
    account.deleteAccount(
      { user },
      {
        fetchBatch: batchedFetch({ ScrubCase: [fakeRows(1, "c")] }),
        destroyBatch: async () => {
          throw new Error("boom");
        },
        destroyUser: async () => {
          userDestroyed = true;
        },
      }
    ),
    /boom/
  );
  assert.equal(userDestroyed, false);
});
