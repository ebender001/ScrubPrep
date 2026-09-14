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
test/                          node:test unit tests (mock the AI client, no network/Parse needed)
scripts/
  lib/parseRest.js               shared Parse REST API helper (used by the scripts below)
  try-generate-prep.js          manual smoke test against the real OpenAI API (direct OpenAI call)
  call-cloud-function.js        calls a deployed Cloud Function via the Parse REST API (bypasses `b4a cloud`)
  seed-specialties.js            idempotently seeds/updates the Specialty catalog via the Parse REST API
  seed-case-types.js            rebuilds the CaseType catalog (specialty as a Pointer) via the Parse REST API
.parse.project                  Parse CLI project config (safe to commit — no secrets)
.parse.local                    Parse CLI local config incl. Master Key — gitignored, never commit
```

## Cloud Functions

| Function | Params | Returns |
|---|---|---|
| `generateScrubPrep` | `{ caseDescription }` | OR Prep JSON (title, case_summary, why_operating, anatomy, operation_overview, things_to_watch, complications, must_know, likely_questions[]) |
| `startPimpSession` | `{ caseDescription, prep, difficulty }` | `{ sessionId, question, progress, done }` |
| `answerPimpQuestion` | `{ sessionId, answer }` | `{ assessment, feedback, teachingPoint, nextQuestion, done, progress }`, or on the last question `{ ..., done: true, summary: { strong, review, twoMinuteReview } }` |
| `generateRapidFire` | `{ caseDescription, prep }` | `{ questions: [{ question, answer }] }` (exactly 5) |
| `listCaseTypes` | none | `{ caseTypes: [{ name, fullName, specialty: { id, name } \| null, featured }] }`, sorted by specialty's sortOrder then the case type's own sortOrder/name |
| `listSpecialties` | none | `{ specialties: [{ id, name }] }`, sorted by sortOrder/name |

`difficulty` is one of `easy | typical | tough | merciless` (defaults to `typical`). Session length scales with difficulty (5 questions for easy/typical, 6 for tough, 7 for merciless).

Pimp Me session state is stored server-side in a `PimpSession` Parse class (`caseDescription`, `prep`, `difficulty`, `history`, `pendingQuestion`, `status`) so the client only ever needs to hold a `sessionId`.

### Specialty & case type catalog

Specialties (e.g. "General Surgery", "Cardiac Surgery", "ENT") live in a `Specialty` Parse class: `name` (String, human-readable), `sortOrder` (Number). Case types (e.g. "Lap Chole", "CABG", "Tonsillectomy") live in a `CaseType` Parse class with a **Pointer** to a `Specialty` row (not a raw string), plus `name` (String — the short/colloquial label shown on the compact quick-pick chip), `fullName` (String — the proper clinical name inserted into the case description field when that chip is tapped, e.g. "Laparoscopic Cholecystectomy" for "Lap Chole"; identical to `name` when there's no common abbreviation), `sortOrder` (Number, order within that specialty), and `featured` (Boolean, whether it should appear as a Home-screen quick-pick). Neither class is hardcoded in the client, so the catalog can grow without an app release.

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

- `ScrubCase` (completed OR Prep case history) is not yet a Parse class — v1 case history is expected to live client-side in the iOS app first (spec allows this).
- `Specialty`/`CaseType` catalog rows must currently be seeded/edited via `scripts/seed-specialties.js` / `scripts/seed-case-types.js` or the dashboard's Database Browser — no admin UI or Cloud Function to write them yet (`listSpecialties`/`listCaseTypes` are read-only).
- No user accounts/auth yet — `PimpSession` objects are created without an owning user and read/written via the master key from Cloud Code. Add `Parse.User` association + ACLs when accounts are introduced.
- PHI detection (`schemas.containsLikelyPHI`) is intentionally minimal (a few obvious patterns) per the product spec — not a compliance-grade PHI scrubber.
