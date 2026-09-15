// Back4App Cloud Code entry point.
// All OpenAI calls happen here (server-side only) — the iOS client never sees an API key.

const prep = require("./scrubPrep/prep");
const pimp = require("./scrubPrep/pimp");
const rapidFire = require("./scrubPrep/rapidFire");
const schemas = require("./scrubPrep/schemas");
const caseTypes = require("./scrubPrep/caseTypes");
const specialties = require("./scrubPrep/specialties");

const MAX_CASE_DESCRIPTION_LENGTH = 300;
const MAX_ANSWER_LENGTH = 2000;

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
    const caseDescription = requireNonEmptyString(
      request.params.caseDescription,
      "caseDescription",
      MAX_CASE_DESCRIPTION_LENGTH
    );
    assertNoPHI(caseDescription);
    try {
      return await prep.generatePrep(caseDescription);
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
    const { question } = await pimp.generateFirstQuestion({
      caseDescription,
      prep: prepContext,
      difficulty,
      previousQuestions,
    });

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
      const result = await pimp.evaluateFinalAnswer({
        caseDescription,
        prep: prepContext,
        difficulty,
        history,
        question: pendingQuestion,
        answer,
      });

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

    const result = await pimp.evaluateAnswer({
      caseDescription,
      prep: prepContext,
      difficulty,
      history,
      question: pendingQuestion,
      answer,
    });

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
    const { questions } = await rapidFire.generateRapidFire({
      caseDescription,
      prep: prepContext,
    });
    return { questions };
  })
);
