// A user's completed Pimp Me sessions, stored server-side as a `PimpMeSession` Parse
// class scoped to `owner` (Pointer<_User>) — persisted so a completed difficulty can be
// reviewed later. Distinct from the ephemeral `PimpSession` class in cloud/main.js, which
// only holds in-progress Q&A state for a single active round and is never itself a
// completed-session record — don't confuse the two.
//
// At most one row per (owner, normalizedDescription, difficulty): see upsertSession,
// which overwrites the existing row instead of inserting a duplicate (mirrors the
// client-side PimpMeSessionStore.save logic this replaces). Same locked-down CLP /
// Master-Key-only access pattern as cloud/scrubPrep/cases.js.

function normalizeDescription(text) {
  return (text || "").trim().toLowerCase();
}

// Dates are sent as explicit ISO8601 strings — see cases.js's serializeCase for why.
function serializeSession(obj) {
  const completedAt = obj.get("completedAt") || obj.updatedAt;
  return {
    id: obj.id,
    caseDescription: obj.get("caseDescription"),
    difficulty: obj.get("difficulty"),
    transcript: obj.get("transcript") || [],
    summary: obj.get("summary") || null,
    completedAt: completedAt.toISOString(),
  };
}

async function fetchSessionObject({ owner, normalizedDescription, difficulty }) {
  const query = new Parse.Query("PimpMeSession");
  query.equalTo("owner", owner);
  query.equalTo("normalizedDescription", normalizedDescription);
  query.equalTo("difficulty", difficulty);
  return query.first({ useMasterKey: true });
}

async function fetchSessionsForCase({ owner, normalizedDescription }) {
  const query = new Parse.Query("PimpMeSession");
  query.equalTo("owner", owner);
  query.equalTo("normalizedDescription", normalizedDescription);
  return query.find({ useMasterKey: true });
}

function newSessionObject() {
  const PimpMeSessionClass = Parse.Object.extend("PimpMeSession");
  return new PimpMeSessionClass();
}

/**
 * Inserts a new completed session, or overwrites the existing one for this exact
 * (owner, case, difficulty) — never duplicates.
 *
 * @param {{ owner: Parse.User, caseDescription: string, difficulty: string, transcript: Array, summary: object }} params
 * @param {{ fetchSessionObject?: typeof fetchSessionObject, newSessionObject?: typeof newSessionObject }} [deps]
 */
async function upsertSession({ owner, caseDescription, difficulty, transcript, summary }, deps = {}) {
  const fetch = deps.fetchSessionObject || fetchSessionObject;
  const createNew = deps.newSessionObject || newSessionObject;
  const normalizedDescription = normalizeDescription(caseDescription);
  const existing = await fetch({ owner, normalizedDescription, difficulty });

  const session = existing || createNew();
  session.set("owner", owner);
  session.set("caseDescription", caseDescription);
  session.set("normalizedDescription", normalizedDescription);
  session.set("difficulty", difficulty);
  session.set("transcript", transcript || []);
  session.set("summary", summary || null);
  session.set("completedAt", new Date());
  await session.save(null, { useMasterKey: true });
  return serializeSession(session);
}

/**
 * @param {{ owner: Parse.User, caseDescription: string }} params
 * @param {{ fetchSessionsForCase?: typeof fetchSessionsForCase }} [deps]
 */
async function listSessionsForCase({ owner, caseDescription }, deps = {}) {
  const fetch = deps.fetchSessionsForCase || fetchSessionsForCase;
  const normalizedDescription = normalizeDescription(caseDescription);
  const objects = await fetch({ owner, normalizedDescription });
  return objects.map(serializeSession);
}

/**
 * Cascade-delete helper used by cases.js's deleteCase — removes every completed session
 * for a case that no longer exists.
 *
 * @param {{ owner: Parse.User, normalizedDescription: string }} params
 * @param {{ fetchSessionsForCase?: typeof fetchSessionsForCase }} [deps]
 */
async function deleteSessionsForCase({ owner, normalizedDescription }, deps = {}) {
  const fetch = deps.fetchSessionsForCase || fetchSessionsForCase;
  const objects = await fetch({ owner, normalizedDescription });
  await Promise.all(objects.map((obj) => obj.destroy({ useMasterKey: true })));
}

module.exports = {
  normalizeDescription,
  fetchSessionObject,
  fetchSessionsForCase,
  upsertSession,
  listSessionsForCase,
  deleteSessionsForCase,
};
