// Back4App Cloud Code entry point.
// All OpenAI calls happen here (server-side only) — the iOS client never sees an API key.

const prep = require("./scrubPrep/prep");
const pimp = require("./scrubPrep/pimp");
const rapidFire = require("./scrubPrep/rapidFire");
const schemas = require("./scrubPrep/schemas");
const caseTypes = require("./scrubPrep/caseTypes");

const MAX_CASE_DESCRIPTION_LENGTH = 300;
const MAX_ANSWER_LENGTH = 2000;

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
    return prep.generatePrep(caseDescription);
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

    const { question } = await pimp.generateFirstQuestion({
      caseDescription,
      prep: prepContext,
      difficulty,
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
