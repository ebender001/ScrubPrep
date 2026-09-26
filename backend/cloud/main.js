// Back4App Cloud Code entry point.
// All OpenAI calls happen here (server-side only) — the iOS client never sees an API key.

const prep = require("./scrubPrep/prep");
const pimp = require("./scrubPrep/pimp");
const rapidFire = require("./scrubPrep/rapidFire");
const schemas = require("./scrubPrep/schemas");
const caseTypes = require("./scrubPrep/caseTypes");
const specialties = require("./scrubPrep/specialties");
const cases = require("./scrubPrep/cases");
const prepCatalog = require("./scrubPrep/prepCatalog");
const pimpMeSessions = require("./scrubPrep/pimpMeSessions");
const cleanup = require("./scrubPrep/cleanup");
const aiClient = require("./scrubPrep/aiClient");
const aiUsage = require("./scrubPrep/aiUsage");
const subscriptions = require("./scrubPrep/subscriptions");
const account = require("./scrubPrep/account");

subscriptions.registerProtectedFieldsGuard();

// Every AI-backed Cloud Function passes this as its `deps` so each underlying OpenAI call
// (prep.js/pimp.js/rapidFire.js all already accept an injectable `generateJSON` for tests)
// also gets logged as an AIUsageEvent row — see scripts/report-ai-costs.js for turning
// those into a cost report. `functionName` tags which Cloud Function the call belongs to;
// `request.user` is attached whenever the client is signed in, even for functions (like
// generateScrubPrep) that don't themselves require it.
function withUsageTracking(functionName, request) {
  return {
    generateJSON: (params) =>
      aiClient.generateJSON(
        Object.assign({}, params, {
          onUsage: (usage, model) =>
            aiUsage.recordUsage({ functionName, model, usage, owner: request.user }),
        })
      ),
  };
}

const MAX_CASE_DESCRIPTION_LENGTH = 300;
const MAX_ANSWER_LENGTH = 2000;
const MAX_PREVIOUS_QUESTIONS = 50;
const MAX_PREVIOUS_QUESTION_LENGTH = 500;

// Rapid Fire's previousQuestions comes straight from the client (unlike Pimp Me's, which
// is derived server-side from stored sessions) — bound its size before it goes into a
// prompt so a misbehaving client can't inflate token usage/cost.
function sanitizePreviousQuestions(value) {
  if (!Array.isArray(value)) return [];
  return value
    .filter((q) => typeof q === "string" && q.trim().length > 0)
    .slice(0, MAX_PREVIOUS_QUESTIONS)
    .map((q) => q.trim().slice(0, MAX_PREVIOUS_QUESTION_LENGTH));
}

// Custom Parse error code (outside Parse's own reserved 1-299/600s range) so the iOS
// client can distinguish "that wasn't a real procedure" from a generic server error and
// show the witty message as-is instead of a generic fallback. Parse Server SDKs also
// accept a plain number for a custom code — it round-trips as ParseError.Code.other with
// otherCode set to this value on the Swift side (see ParseError.swift's Decodable init).
const UNRECOGNIZED_CASE_ERROR_CODE = 4001;

const UNRECOGNIZED_CASE_MESSAGES = [
  "That doesn't look like a real operation. Try again, or I'm telling your chief resident.",
  "I've read every surgical textbook there is, and that's not in any of them. Try again with an actual case.",
  "That's not a procedure — that's a cry for coffee. Try again with something you'd actually scrub in on.",
  "Nice try, but that's not on today's OR schedule. Give me a real operation.",
  "Even the attending is confused by that one. Try again before someone pages you.",
];

function randomUnrecognizedCaseMessage() {
  const index = Math.floor(Math.random() * UNRECOGNIZED_CASE_MESSAGES.length);
  return UNRECOGNIZED_CASE_MESSAGES[index];
}

// So a new session (any difficulty) doesn't open with the same first question as an
// earlier session on this same case — e.g. easy and typical both asking "why does this
// patient have this diagnosis" verbatim.
async function collectPreviousQuestions(caseDescription) {
  const query = new Parse.Query("PimpSession");
  query.equalTo("caseDescription", caseDescription);
  query.limit(50);
  const sessions = await query.find({ useMasterKey: true });
  const questions = [];
  for (const session of sessions) {
    for (const turn of session.get("history") || []) {
      if (turn && turn.question) questions.push(turn.question);
    }
    const pendingQuestion = session.get("pendingQuestion");
    if (pendingQuestion) questions.push(pendingQuestion);
  }
  return questions;
}

function requireNonEmptyString(value, fieldName, maxLength) {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new Parse.Error(Parse.Error.VALIDATION_ERROR, `${fieldName} is required.`);
  }
  if (maxLength && value.length > maxLength) {
    throw new Parse.Error(
      Parse.Error.VALIDATION_ERROR,
      `${fieldName} must be ${maxLength} characters or fewer.`
    );
  }
  return value.trim();
}

// Cases and Pimp Me sessions are per-user (backend is the single source of truth, not
// the device) — every function that reads/writes them requires a signed-in user. Unlike
// requireNonEmptyString's VALIDATION_ERROR, this uses INVALID_SESSION_TOKEN (209) so a
// client can distinguish "you're not signed in" from a bad request.
function requireUser(request) {
  if (!request.user) {
    throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Please sign in and try again.");
  }
  return request.user;
}

function assertNoPHI(caseDescription) {
  if (schemas.containsLikelyPHI(caseDescription)) {
    throw new Parse.Error(
      Parse.Error.VALIDATION_ERROR,
      "Please remove patient names, dates of birth, medical record numbers, or other identifying information and try again."
    );
  }
}

// Wraps a handler so unexpected/internal errors never leak raw details to the client.
function safeHandler(handler) {
  return async (request) => {
    try {
      return await handler(request);
    } catch (err) {
      if (err instanceof Parse.Error) throw err;
      console.error(err);
      throw new Parse.Error(
        Parse.Error.INTERNAL_SERVER_ERROR,
        "Scrub Prep wasn't able to complete this request. Please try again."
      );
    }
  };
}

Parse.Cloud.define(
  "generateScrubPrep",
  safeHandler(async (request) => {
    const user = requireUser(request);
    const caseDescription = requireNonEmptyString(
      request.params.caseDescription,
      "caseDescription",
      MAX_CASE_DESCRIPTION_LENGTH
    );
    assertNoPHI(caseDescription);

    // Cross-user cache: if anyone has already generated this exact (normalized) case
    // description under the current prompt version, skip OpenAI entirely. See
    // prepCatalog.js's file comment for why this is separate from ScrubCase (which is
    // per-owner and exists for a different reason).
    const normalizedDescription = prepCatalog.normalizeDescription(caseDescription);
    const cached = await prepCatalog.getCachedPrep(normalizedDescription);
    if (cached) return cached;

    // Whether this request is even allowed to reach here (active subscription, or an
    // unused complimentary case) is decided entirely client-side via StoreKit 2 — see
    // SubscriptionManager.swift and HomeViewModel.resolvePrep. This backend does not
    // independently enforce it; see subscriptions.js's file comment for the accepted
    // tradeoff.
    try {
      const result = await prep.generatePrep(caseDescription, withUsageTracking("generateScrubPrep", request));
      await prepCatalog.upsertCatalogEntry({ caseDescription, normalizedDescription, prep: result });
      return result;
    } catch (err) {
      if (err instanceof prep.UnrecognizedCaseError) {
        throw new Parse.Error(UNRECOGNIZED_CASE_ERROR_CODE, randomUnrecognizedCaseMessage());
      }
      throw err;
    }
  })
);

Parse.Cloud.define(
  "startPimpSession",
  safeHandler(async (request) => {
    const caseDescription = requireNonEmptyString(
      request.params.caseDescription,
      "caseDescription",
      MAX_CASE_DESCRIPTION_LENGTH
    );
    const { prep: prepContext, difficulty } = request.params;

    const previousQuestions = await collectPreviousQuestions(caseDescription);
    const { question } = await pimp.generateFirstQuestion(
      {
        caseDescription,
        prep: prepContext,
        difficulty,
        previousQuestions,
      },
      withUsageTracking("startPimpSession", request)
    );

    const PimpSession = Parse.Object.extend("PimpSession");
    const session = new PimpSession();
    session.set("caseDescription", caseDescription);
    session.set("prep", prepContext || null);
    session.set("difficulty", difficulty || "typical");
    session.set("history", []);
    session.set("pendingQuestion", question);
    session.set("status", "active");
    await session.save(null, { useMasterKey: true });

    return {
      sessionId: session.id,
      question,
      progress: { index: 0, total: pimp.getQuestionTarget(difficulty) },
      done: false,
    };
  })
);

Parse.Cloud.define(
  "answerPimpQuestion",
  safeHandler(async (request) => {
    const sessionId = requireNonEmptyString(request.params.sessionId, "sessionId");
    const answer = requireNonEmptyString(request.params.answer, "answer", MAX_ANSWER_LENGTH);

    const query = new Parse.Query("PimpSession");
    let session;
    try {
      session = await query.get(sessionId, { useMasterKey: true });
    } catch (err) {
      throw new Parse.Error(Parse.Error.OBJECT_NOT_FOUND, "This Pimp Me session was not found.");
    }

    if (session.get("status") !== "active") {
      throw new Parse.Error(
        Parse.Error.OPERATION_FORBIDDEN,
        "This Pimp Me session has already ended."
      );
    }

    const caseDescription = session.get("caseDescription");
    const prepContext = session.get("prep");
    const difficulty = session.get("difficulty");
    const history = session.get("history") || [];
    const pendingQuestion = session.get("pendingQuestion");
    const target = pimp.getQuestionTarget(difficulty);
    const isFinal = pimp.isSessionComplete(history.length + 1, difficulty);

    if (isFinal) {
      const result = await pimp.evaluateFinalAnswer(
        {
          caseDescription,
          prep: prepContext,
          difficulty,
          history,
          question: pendingQuestion,
          answer,
        },
        withUsageTracking("answerPimpQuestion", request)
      );

      const updatedHistory = [
        ...history,
        {
          question: pendingQuestion,
          answer,
          assessment: result.assessment,
          concept: result.concept,
        },
      ];
      session.set("history", updatedHistory);
      session.set("pendingQuestion", null);
      session.set("status", "complete");
      await session.save(null, { useMasterKey: true });

      return {
        sessionId: session.id,
        assessment: result.assessment,
        feedback: result.feedback,
        teachingPoint: result.teaching_point,
        done: true,
        progress: { index: target, total: target },
        summary: {
          strong: result.strong,
          review: result.review,
          twoMinuteReview: result.two_minute_review,
        },
      };
    }

    const result = await pimp.evaluateAnswer(
      {
        caseDescription,
        prep: prepContext,
        difficulty,
        history,
        question: pendingQuestion,
        answer,
      },
      withUsageTracking("answerPimpQuestion", request)
    );

    const updatedHistory = [
      ...history,
      {
        question: pendingQuestion,
        answer,
        assessment: result.assessment,
        concept: result.concept,
      },
    ];
    session.set("history", updatedHistory);
    session.set("pendingQuestion", result.next_question);
    await session.save(null, { useMasterKey: true });

    return {
      sessionId: session.id,
      assessment: result.assessment,
      feedback: result.feedback,
      teachingPoint: result.teaching_point,
      nextQuestion: result.next_question,
      done: false,
      progress: { index: updatedHistory.length, total: target },
    };
  })
);

Parse.Cloud.define(
  "listCaseTypes",
  safeHandler(async () => {
    const items = await caseTypes.listCaseTypes();
    return { caseTypes: items };
  })
);

Parse.Cloud.define(
  "listSpecialties",
  safeHandler(async () => {
    const items = await specialties.listSpecialties();
    return { specialties: items };
  })
);

Parse.Cloud.define(
  "generateRapidFire",
  safeHandler(async (request) => {
    const caseDescription = requireNonEmptyString(
      request.params.caseDescription,
      "caseDescription",
      MAX_CASE_DESCRIPTION_LENGTH
    );
    const { prep: prepContext } = request.params;
    const previousQuestions = sanitizePreviousQuestions(request.params.previousQuestions);
    const { questions } = await rapidFire.generateRapidFire(
      {
        caseDescription,
        prep: prepContext,
        previousQuestions,
      },
      withUsageTracking("generateRapidFire", request)
    );
    return { questions };
  })
);

Parse.Cloud.define(
  "listCases",
  safeHandler(async (request) => {
    const user = requireUser(request);
    const items = await cases.listCasesForOwner(user);
    return { cases: items };
  })
);

Parse.Cloud.define(
  "saveCase",
  safeHandler(async (request) => {
    const user = requireUser(request);
    const caseDescription = requireNonEmptyString(
      request.params.caseDescription,
      "caseDescription",
      MAX_CASE_DESCRIPTION_LENGTH
    );
    const { prep: prepContext, specialtyId } = request.params;
    // Optional — an unknown/missing specialtyId just saves the case without one rather
    // than failing the save (the prep itself is what matters here).
    const specialty =
      typeof specialtyId === "string" && specialtyId.trim().length > 0
        ? await cases.fetchSpecialtyById(specialtyId.trim())
        : null;
    const savedCase = await cases.upsertCase({ owner: user, caseDescription, prep: prepContext, specialty });

    // The complimentary allowance is marked used HERE, not in generateScrubPrep — only
    // once the case this generation produced has actually been durably saved. A failed
    // generation, or a network drop before this call ever happens, never touches the
    // flag (see subscriptions.js — it's a no-op if already true, and this is the only
    // place it's ever set).
    await subscriptions.markComplimentaryCaseUsed(user);

    return { case: savedCase };
  })
);

Parse.Cloud.define(
  "markCaseReviewed",
  safeHandler(async (request) => {
    const user = requireUser(request);
    const caseId = requireNonEmptyString(request.params.caseId, "caseId");
    const updated = await cases.markCaseReviewed({ caseId, owner: user });
    if (!updated) {
      throw new Parse.Error(Parse.Error.OBJECT_NOT_FOUND, "This case was not found.");
    }
    return { success: true };
  })
);

Parse.Cloud.define(
  "deleteCase",
  safeHandler(async (request) => {
    const user = requireUser(request);
    const caseId = requireNonEmptyString(request.params.caseId, "caseId");
    const deleted = await cases.deleteCase({ caseId, owner: user });
    if (!deleted) {
      throw new Parse.Error(Parse.Error.OBJECT_NOT_FOUND, "This case was not found.");
    }
    return { success: true };
  })
);

Parse.Cloud.define(
  "listPimpMeSessions",
  safeHandler(async (request) => {
    const user = requireUser(request);
    const caseDescription = requireNonEmptyString(
      request.params.caseDescription,
      "caseDescription",
      MAX_CASE_DESCRIPTION_LENGTH
    );
    const sessions = await pimpMeSessions.listSessionsForCase({ owner: user, caseDescription });
    return { sessions };
  })
);

Parse.Cloud.define(
  "savePimpMeSession",
  safeHandler(async (request) => {
    const user = requireUser(request);
    const caseDescription = requireNonEmptyString(
      request.params.caseDescription,
      "caseDescription",
      MAX_CASE_DESCRIPTION_LENGTH
    );
    const { difficulty, transcript, summary } = request.params;
    const session = await pimpMeSessions.upsertSession({
      owner: user,
      caseDescription,
      difficulty: difficulty || "typical",
      transcript,
      summary,
    });
    return { session };
  })
);

// In-app account deletion (App Store Guideline 5.1.1(v)) — see account.js for exactly
// what's removed. Only ever deletes the caller's own account: the user comes from the
// session token, never from a client-supplied id.
Parse.Cloud.define(
  "deleteAccount",
  safeHandler(async (request) => {
    const user = requireUser(request);
    await account.deleteAccount({ user });
    return { success: true };
  })
);

// Scheduled from the Back4App dashboard (Server Settings -> Job Scheduler after
// deploying) — not triggered by the client. Optional `maxAgeDays` param, defaults to 1.
Parse.Cloud.job("cleanupOldPimpSessions", async (request) => {
  const deletedCount = await cleanup.cleanupOldPimpSessions({ maxAgeDays: request.params.maxAgeDays });
  request.message(`Deleted ${deletedCount} PimpSession row(s).`);
});
