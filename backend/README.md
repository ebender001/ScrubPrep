# Scrub Prep — Backend (Back4App Cloud Code)

Parse Server Cloud Code that generates all AI content for Scrub Prep. The iOS app never talks to OpenAI directly — it only calls these Cloud Functions.

## Structure

```
cloud/
  main.js                     Cloud Function definitions + Parse persistence for Pimp Me sessions
  scrubPrep/
    aiClient.js                OpenAI Chat Completions wrapper (Structured Outputs / json_schema, strict)
    prompts.js                 System prompts + user-prompt builders for prep/pimp/rapid fire
    schemas.js                 JSON schemas for OpenAI + hand-rolled response validators + PHI heuristic
    prep.js                    generatePrep(caseDescription)
    pimp.js                    Pimp Me session logic (pure — no Parse dependency, unit-testable)
    rapidFire.js                generateRapidFire({ caseDescription, prep })
    caseTypes.js                listCaseTypes() — reads the CaseType catalog Parse class
    specialties.js              listSpecialties() — reads the Specialty catalog Parse class
    cases.js                    a signed-in user's saved Cases (ScrubCase Parse class)
    pimpMeSessions.js            a signed-in user's completed Pimp Me sessions (PimpMeSession Parse class)
    cleanup.js                  cleanupOldPimpSessions job — deletes stale ephemeral PimpSession rows
    aiCost.js                    USD-per-1M-token pricing table + estimateCostUSD(model, usage)
    aiUsage.js                   recordUsage(...) — logs one AIUsageEvent row per OpenAI API call
    subscriptions.js              subscription entitlement + complimentary-first-case allowance (access control for generateScrubPrep), and the _User beforeSave guard protecting subscription fields from direct client writes
test/                          node:test unit tests (mock the AI client, no network/Parse needed)
scripts/
  lib/parseRest.js               shared Parse REST API helper (used by the scripts below)
  try-generate-prep.js          manual smoke test against the real OpenAI API (direct OpenAI call)
  call-cloud-function.js        calls a deployed Cloud Function via the Parse REST API (bypasses `b4a cloud`)
  seed-specialties.js            idempotently seeds/updates the Specialty catalog via the Parse REST API
  seed-case-types.js            rebuilds the CaseType catalog (specialty as a Pointer) via the Parse REST API
  setup-user-data-schema.js      creates/updates the ScrubCase and PimpMeSession classes with no public CLP access
  setup-ai-usage-schema.js      creates/updates the AIUsageEvent class with no public CLP access
  report-ai-costs.js            prints an AI cost report (by Cloud Function, by model, projected monthly) from AIUsageEvent rows
  setup-user-subscription-fields.js  adds the subscription/complimentary-case fields to the built-in _User class
.parse.project                  Parse CLI project config (safe to commit — no secrets)
.parse.local                    Parse CLI local config incl. Master Key — gitignored, never commit
```

## Cloud Functions

| Function | Params | Returns |
|---|---|---|
| `generateScrubPrep` | `{ caseDescription }` (requires sign-in) | OR Prep JSON (title, case_summary, why_operating, anatomy, operation_overview, things_to_watch, complications, must_know, likely_questions[]), or a Parse.Error (code 4001, a witty message) if the description isn't recognized as a real procedure. This function does **not** itself check subscription/complimentary-case eligibility — see "Subscriptions & complimentary case" below |
| `startPimpSession` | `{ caseDescription, prep, difficulty }` | `{ sessionId, question, progress, done }` |
| `answerPimpQuestion` | `{ sessionId, answer }` | `{ assessment, feedback, teachingPoint, nextQuestion, done, progress }`, or on the last question `{ ..., done: true, summary: { strong, review, twoMinuteReview } }` |
| `generateRapidFire` | `{ caseDescription, prep }` | `{ questions: [{ question, answer }] }` (exactly 5) |
| `listCaseTypes` | none | `{ caseTypes: [{ name, fullName, specialty: { id, name } \| null, featured }] }`, sorted by specialty's sortOrder then the case type's own sortOrder/name |
| `listSpecialties` | none | `{ specialties: [{ id, name, exampleCaseDescription }] }`, sorted by sortOrder/name |
| `listCases` | none (requires sign-in) | `{ cases: [{ id, caseDescription, prep, createdAt, updatedAt, lastReviewedAt }] }`, sorted by `updatedAt` desc |
| `saveCase` | `{ caseDescription, prep }` (requires sign-in) | `{ case: {...} }` — inserts, or updates in place if this (normalized) case was already saved. Marks the complimentary case used (if not already) — see "Subscriptions & complimentary case" below |
| `markCaseReviewed` | `{ caseId }` (requires sign-in) | `{ success: true }` |
| `deleteCase` | `{ caseId }` (requires sign-in) | `{ success: true }` — also deletes any completed Pimp Me sessions for that case |
| `listPimpMeSessions` | `{ caseDescription }` (requires sign-in) | `{ sessions: [{ id, caseDescription, difficulty, transcript, summary, completedAt }] }`, every difficulty completed for that case |
| `savePimpMeSession` | `{ caseDescription, difficulty, transcript, summary }` (requires sign-in) | `{ session: {...} }` — inserts, or overwrites the existing row for that (case, difficulty) |

`difficulty` is one of `easy | typical | tough` (defaults to `typical`). Session length scales with difficulty (4 questions for easy, 5 for typical, 6 for tough).

### Unrecognized case descriptions

The `or_prep` JSON schema (`cloud/scrubPrep/schemas.js`) requires a `recognized` boolean. The model sets it `false` (and fills every other field with honest placeholder content instead of inventing a fake operation) when the case description isn't a real, identifiable procedure — gibberish, unrelated text, etc. `cloud/scrubPrep/prep.js` turns that into an `UnrecognizedCaseError` (thrown immediately, no retry — retrying gibberish with the same prompt won't make it real), which `generateScrubPrep` in `cloud/main.js` converts into a `Parse.Error` with a custom code (`4001`) and a randomly-picked witty message (see `UNRECOGNIZED_CASE_MESSAGES`). The iOS client checks for this specific code to show the message as-is instead of a generic failure message, and — since no prep is returned — never saves it to case history.

Pimp Me session state is stored server-side in a `PimpSession` Parse class (`caseDescription`, `prep`, `difficulty`, `history`, `pendingQuestion`, `status`) so the client only ever needs to hold a `sessionId`. This is an **ephemeral** scratchpad for a single in-progress round — don't confuse it with `PimpMeSession` below, the persisted record of a *completed* session.

A `cleanupOldPimpSessions` Cloud Job (`cloud/scrubPrep/cleanup.js`) deletes any `PimpSession` row not updated in the last day (configurable via an optional `maxAgeDays` param) — a session is meant to finish in minutes, so anything older is abandoned, and nothing ever reads a `PimpSession` row again once it's stale. This only runs when triggered — **after deploying, schedule it once in the Back4App dashboard** (Server Settings → Job Scheduler → pick `cleanupOldPimpSessions`, e.g. daily) or trigger it manually from there; there's no way to schedule it from this repo.

### User accounts, Cases, and Pimp Me sessions

Sign-up/sign-in/sign-out/password-reset go straight through Parse's built-in `_User` class (email/password) and the built-in Apple auth adapter (Sign in with Apple) — no custom Cloud Code needed for any of that. Cases (completed OR Preps) and completed Pimp Me sessions are the backend's authoritative copy (not the device): `ScrubCase` and `PimpMeSession` Parse classes, each with an `owner` (Pointer<_User>) field and a `normalizedDescription` field for case-identity dedup (at most one `ScrubCase` per (owner, normalizedDescription), at most one `PimpMeSession` per (owner, normalizedDescription, difficulty) — see `cloud/scrubPrep/cases.js` / `cloud/scrubPrep/pimpMeSessions.js`).

Both classes have every Class-Level Permission locked to nobody (`find/get/create/update/delete/addField: {}`) — the six Cloud Functions above are the *only* way to reach them, all via the Master Key with ownership enforced by an explicit `owner` query constraint (the same pattern the ephemeral `PimpSession` class already uses, not Parse ACLs). Set up (or update) these two classes' schema/CLPs with:

```
node scripts/setup-user-data-schema.js
```

Safe to re-run.

### AI cost tracking

Every actual OpenAI API call — from `generateScrubPrep`, `startPimpSession`, `answerPimpQuestion`, and `generateRapidFire` — is logged as its own row in an `AIUsageEvent` Parse class (`cloud/scrubPrep/aiUsage.js`, called from `cloud/main.js`'s `withUsageTracking` helper): `functionName`, `model`, `promptTokens`, `completionTokens`, `totalTokens`, `estimatedCostUSD`, and `owner` (Pointer<_User>, when the caller is signed in). Estimated cost comes from a hand-maintained USD-per-1M-token pricing table in `cloud/scrubPrep/aiCost.js` — **verify those numbers against <https://openai.com/api/pricing/> and update them if OpenAI has changed pricing** before trusting a report for a real financial decision (e.g. setting a subscription price). Logging a usage row can never fail or slow down the AI call it's measuring — errors are caught and logged, never thrown.

Like `AIUsageEvent`'s Class-Level Permissions are locked to nobody — Master Key/Cloud Code only. Set it up once with:

```
node scripts/setup-ai-usage-schema.js
```

Then, any time you want to check actual spend or estimate a subscription price, run this from the `backend/` folder (where this README lives — `scripts/` is relative to it):

```
node scripts/report-ai-costs.js            # all-time
node scripts/report-ai-costs.js --days 30  # last 30 days only
```

This prints total estimated cost, a breakdown by Cloud Function and by model, average cost per signed-in user, and a projected monthly cost extrapolated from the observed date range — a starting point for "what do we need to charge per subscriber to cover AI spend," not a substitute for also accounting for margin, non-AI costs, and inactive/free users.

### Subscriptions & complimentary case

Every signed-in user may generate exactly one case for free (their "complimentary case");
generating any additional case requires an active auto-renewing subscription (two
products, same access level, different billing durations: monthly and every 3 months —
see `ios/ScrubPrep/ScrubPrep/Services/SubscriptionManager.swift`).

**Trust model — this is deliberately a purely client-side gate.** Whether a subscription
is currently active is determined entirely on-device, by asking StoreKit 2 directly
(`Transaction.currentEntitlements`, which already reflects Apple-managed renewals,
cancellations, and billing grace periods) — this backend never sees a receipt, a JWS, or
any subscription-status report at all, and has **no Cloud Function, database row, App
Store Server Notifications webhook, or App Store Server API polling** for subscription
state. This is a deliberate simplification over an earlier version of this feature, which
went through two more complex designs in turn (independent server-side JWS signature
verification with Apple's root certificate, then a `_User`-based design where the client
reported its own StoreKit-verified status for the backend to store and trust) before
landing here, which needs no backend involvement at all for the "is this account
currently subscribed" question.

**Accepted tradeoff:** since there is no server-side check, a modified client binary
could in principle skip its own paywall/entitlement check and call `generateScrubPrep`
directly without ever having subscribed. This backend does not defend against that — it
matches how most comparable low-price subscription apps operate, and was an explicit,
informed choice for this app rather than an oversight.

The **only** durable, backend-side state related to any of this is
`hasUsedComplimentaryCase` (Boolean) on `_User` (see
`scripts/setup-user-subscription-fields.js`) — whether this account has ever had a case
saved for free. `saveCase` sets it to `true` (via
`cloud/scrubPrep/subscriptions.js`'s `markComplimentaryCaseUsed`, a no-op if already true)
*after* the resulting case is actually saved — not at generation time, so a generation
that succeeds but is never saved (e.g. the client crashes before calling `saveCase`) never
costs the student their one free case, and a failed generation never touches the flag at
all. It is never reset by deleting cases (`deleteCase` does not touch it), so it can't be
farmed by generating and deleting cases repeatedly.

This field isn't writable by the client SDK despite living on `_User`, whose CLP
intentionally allows authenticated self-update (required for signup/login, and for e.g.
changing email). `cloud/scrubPrep/subscriptions.js`'s `registerProtectedFieldsGuard`
installs a `beforeSave` trigger on `_User` that rejects any *non*-Master-Key save touching
this field — allowing normal self-updates (email, etc.) through, and (covered by a test)
explicitly not blocking the very first signup save, since a brand-new `_User` reports
every field as "dirty" regardless of what the client actually set.

The iOS app reads this flag directly off the signed-in user's own `_User` row (a plain
`fetch()` on `User.current`, via ParseSwift — no dedicated Cloud Function) right before
deciding whether a *new* case requires the paywall; see
`HomeViewModel.refreshComplimentaryCaseStatus()`. Because `_User`'s default CLP allows a
user to read their own row, no schema/CLP change was needed for this.

The app's earlier subscription designs also added `appAccountToken`,
`subscriptionStatus`, `subscriptionProductId`, `subscriptionExpiresAt`,
`subscriptionGracePeriodExpiresAt`, `subscriptionAutoRenewStatus`,
`subscriptionAutoRenewProductId`, `subscriptionOriginalTransactionId`, and
`subscriptionLastReportedAt` columns to `_User`. None of these are read, written, or
declared anywhere in this codebase anymore — they may still exist as harmless unused
columns on an already-deployed database. Dropping them is optional cleanup (Back4App's
Database Browser, or a one-off `PUT /schemas/_User` with `{"__op": "Delete"}` for each
field) — not required for correctness, since nothing reads or writes them.

Set up the schema once (safe to re-run):

```
node scripts/setup-user-subscription-fields.js
```

### Specialty & case type catalog

Specialties (e.g. "General Surgery", "Cardiac Surgery", "ENT") live in a `Specialty` Parse class: `name` (String, human-readable), `sortOrder` (Number), and `exampleCaseDescription` (String — the example shown in the iOS case-entry field once that specialty is selected, e.g. "Lap chole for acute cholecystitis" for General Surgery; the client falls back to a generic example if this is missing). Case types (e.g. "Lap Chole", "CABG", "Tonsillectomy") live in a `CaseType` Parse class with a **Pointer** to a `Specialty` row (not a raw string), plus `name` (String — the short/colloquial label shown on the compact quick-pick chip), `fullName` (String — the proper clinical name inserted into the case description field when that chip is tapped, e.g. "Laparoscopic Cholecystectomy" for "Lap Chole"; identical to `name` when there's no common abbreviation), `sortOrder` (Number, order within that specialty), and `featured` (Boolean, whether it should appear as a Home-screen quick-pick). Neither class is hardcoded in the client, so the catalog can grow without an app release.

Seed or update the catalog with:

```
node scripts/seed-specialties.js   # upserts Specialty rows by name — safe to re-run
node scripts/seed-case-types.js    # rebuilds CaseType rows (also re-runs the specialty seed first)
```

`seed-case-types.js` *deletes and recreates* every `CaseType` row (rather than upserting) because Parse Server locks a field's type to whatever it first saw — the `specialty` column used to be a String, and writing a Pointer into that same column fails until the class schema is rebuilt fresh. `CaseType` is pure seed data (nothing references its objectIds elsewhere), so this is safe; `Specialty` rows are upserted in place instead since their `name` values are meaningful identifiers on their own.

## Setup

1. `cp .env.example .env` and fill in your Back4App keys (App Settings → Security & Keys) and your `OPENAI_API_KEY`. `.env` is only used by the local test/scripts below — it is **not** read by deployed Cloud Code.
2. In the Back4App dashboard, go to **Server Settings → Cloud Code → Environment Variables** (or **App Settings → Server Settings**, naming varies by plan) and set `OPENAI_API_KEY` and `OPENAI_MODEL` there. This is required for the deployed functions to work.
3. Install the Back4App CLI if you don't have it: `npm install -g back4app-cli` (or use the dashboard's Cloud Code web editor / GitHub deploy instead — no CLI required either way).

## Running tests

```
npm test
```

Runs Node's built-in test runner (`node --test`) over `test/`. All tests mock the AI client — no OpenAI or Parse credentials needed.

## Manual smoke test (real OpenAI call)

```
OPENAI_API_KEY=sk-... node scripts/try-generate-prep.js "Laparoscopic cholecystectomy for acute cholecystitis"
```

Prints the generated OR Prep JSON to the console.

## Deploying to Back4App

- **Back4App CLI**: `b4a login`, then link this directory to your app once with `b4a add "<Your App Name>"` (writes `.parse.project`; run `b4a migrate` afterward if it instead produces a legacy `config/global.json` — the CLI prefers `.parse.project`/`.parse.local`), `b4a default "<Your App Name>"` to make it the default, then `b4a deploy` from inside `backend/` any time after.
- **Dashboard Cloud Code editor**: paste the contents of `cloud/main.js` and each `cloud/scrubPrep/*.js` file into the dashboard's Cloud Code section, preserving the same relative paths.
- **GitHub integration**: connect this repo's `backend/` folder as the Cloud Code source in the Back4App dashboard for auto-deploy on push, if available for this app.

Note: on this app, the very first release ever created needed one manual "Deploy" click in the dashboard's Cloud Code page before it took effect (until then, the running server logged `main.js not found` and registered zero functions, despite `b4a deploy` reporting success). Every `b4a deploy` since then has taken effect immediately with no further dashboard interaction — that one-time activation may just be a new-app quirk.

After deploying, set `OPENAI_API_KEY` / `OPENAI_MODEL` as server environment variables in the dashboard (step 2 above) if you haven't already — the deployed functions read them via `process.env`.

## Verifying a deploy actually took effect

The `b4a cloud <function>` CLI command returned `null` for both real and nonexistent function names on this app — it's unreliable, don't trust it. Instead call the REST API directly:

```
node scripts/call-cloud-function.js generateScrubPrep '{"caseDescription":"Laparoscopic cholecystectomy for acute cholecystitis"}'
```

(reads `PARSE_APP_ID`/`PARSE_MASTER_KEY` from `backend/.env` — see Setup step 1 — or pass them inline as env vars). Get the Master Key from **App Settings → Security & Keys**; treat it as compromised and rotate it if it's ever typed into a shared/logged terminal session. A real HTTP 200 with generated JSON (or a real Parse error code) means the deploy is live; `main.js not found` in `b4a logs` means the code isn't loading at all.

## Notes / TODOs for later phases

- `Specialty`/`CaseType` catalog rows must currently be seeded/edited via `scripts/seed-specialties.js` / `scripts/seed-case-types.js` or the dashboard's Database Browser — no admin UI or Cloud Function to write them yet (`listSpecialties`/`listCaseTypes` are read-only).
- The ephemeral `PimpSession` class (in-progress Q&A scratchpad, see `startPimpSession`/`answerPimpQuestion`) still has no owning user and is read/written purely via the Master Key — unlike `ScrubCase`/`PimpMeSession`, it was left as-is since it holds nothing worth attributing to an account (it's discarded once a session completes and gets persisted as a `PimpMeSession`).
- PHI detection (`schemas.containsLikelyPHI`) is intentionally minimal (a few obvious patterns) per the product spec — not a compliance-grade PHI scrubber.
- Subscription state is trusted from the client's own StoreKit 2 on-device verification, not independently re-verified server-side — see "Subscriptions & complimentary case" for the reasoning and the accepted tradeoff (a jailbroken/tampered client could report a fake status; it cannot reset its own complimentary flag).
- The complimentary-case flag isn't protected by a reservation/idempotency system — a genuinely concurrent double-tap can trigger an extra OpenAI call, though never a second saved complimentary case — see "Subscriptions & complimentary case" for the reasoning behind this deliberate simplification.
