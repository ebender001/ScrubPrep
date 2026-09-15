const { test } = require("node:test");
const assert = require("node:assert/strict");
const cleanup = require("../cloud/scrubPrep/cleanup");

function fakeSession(id) {
  return { id };
}

test("cleanupOldPimpSessions deletes across multiple batches until none remain", async () => {
  const batch1 = [fakeSession("a"), fakeSession("b")];
  const batch2 = [fakeSession("c")];
  let call = 0;
  const destroyedBatches = [];
  const fetchStaleSessionsBatch = async () => {
    call += 1;
    if (call === 1) return batch1;
    if (call === 2) return batch2;
    return [];
  };
  const destroyBatch = async (objects) => {
    destroyedBatches.push(objects);
  };

  const total = await cleanup.cleanupOldPimpSessions(
    {},
    { fetchStaleSessionsBatch, destroyBatch, now: () => new Date("2024-01-10T00:00:00Z") }
  );

  assert.equal(total, 3);
  assert.equal(destroyedBatches.length, 2);
});

test("cleanupOldPimpSessions returns 0 and never calls destroy when nothing is stale", async () => {
  const total = await cleanup.cleanupOldPimpSessions(
    {},
    {
      fetchStaleSessionsBatch: async () => [],
      destroyBatch: async () => assert.fail("destroyBatch should not be called"),
    }
  );
  assert.equal(total, 0);
});

test("cleanupOldPimpSessions defaults the cutoff to 1 day ago", async () => {
  let capturedCutoff;
  await cleanup.cleanupOldPimpSessions(
    {},
    {
      fetchStaleSessionsBatch: async (cutoff) => {
        capturedCutoff = cutoff;
        return [];
      },
      destroyBatch: async () => {},
      now: () => new Date("2024-01-10T00:00:00Z"),
    }
  );
  assert.equal(capturedCutoff.toISOString(), "2024-01-09T00:00:00.000Z");
});

test("cleanupOldPimpSessions honors a custom maxAgeDays", async () => {
  let capturedCutoff;
  await cleanup.cleanupOldPimpSessions(
    { maxAgeDays: 7 },
    {
      fetchStaleSessionsBatch: async (cutoff) => {
        capturedCutoff = cutoff;
        return [];
      },
      destroyBatch: async () => {},
      now: () => new Date("2024-01-10T00:00:00Z"),
    }
  );
  assert.equal(capturedCutoff.toISOString(), "2024-01-03T00:00:00.000Z");
});

test("cleanupOldPimpSessions ignores an invalid maxAgeDays and falls back to the default", async () => {
  let capturedCutoff;
  await cleanup.cleanupOldPimpSessions(
    { maxAgeDays: -5 },
    {
      fetchStaleSessionsBatch: async (cutoff) => {
        capturedCutoff = cutoff;
        return [];
      },
      destroyBatch: async () => {},
      now: () => new Date("2024-01-10T00:00:00Z"),
    }
  );
  assert.equal(capturedCutoff.toISOString(), "2024-01-09T00:00:00.000Z");
});
