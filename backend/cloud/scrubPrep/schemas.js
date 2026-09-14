// JSON Schemas passed to OpenAI Structured Outputs (response_format: json_schema, strict)
// plus lightweight hand-rolled validators used as defense-in-depth after parsing.

const LIKELY_QUESTION_ITEM = {
  type: "object",
  properties: {
    question: { type: "string" },
    answer: { type: "string" },
  },
  required: ["question", "answer"],
  additionalProperties: false,
};

const PREP_JSON_SCHEMA = {
  type: "object",
  properties: {
    recognized: { type: "boolean" },
    title: { type: "string" },
    case_summary: { type: "string" },
    why_operating: { type: "array", items: { type: "string" } },
    anatomy: { type: "array", items: { type: "string" } },
    operation_overview: { type: "array", items: { type: "string" } },
    things_to_watch: { type: "array", items: { type: "string" } },
    complications: { type: "array", items: { type: "string" } },
    must_know: { type: "array", items: { type: "string" } },
    likely_questions: { type: "array", items: LIKELY_QUESTION_ITEM },
  },
  required: [
    "recognized",
    "title",
    "case_summary",
    "why_operating",
    "anatomy",
    "operation_overview",
    "things_to_watch",
    "complications",
    "must_know",
    "likely_questions",
  ],
  additionalProperties: false,
};

const PIMP_FIRST_QUESTION_SCHEMA = {
  type: "object",
  properties: {
    question: { type: "string" },
  },
  required: ["question"],
  additionalProperties: false,
};

const ASSESSMENT_ENUM = ["correct", "partially_correct", "incorrect"];

const PIMP_EVAL_SCHEMA = {
  type: "object",
  properties: {
    assessment: { type: "string", enum: ASSESSMENT_ENUM },
    feedback: { type: "string" },
    teaching_point: { type: "string" },
    concept: { type: "string" },
    next_question: { type: "string" },
  },
  required: ["assessment", "feedback", "teaching_point", "concept", "next_question"],
  additionalProperties: false,
};

const PIMP_FINAL_EVAL_SCHEMA = {
  type: "object",
  properties: {
    assessment: { type: "string", enum: ASSESSMENT_ENUM },
    feedback: { type: "string" },
    teaching_point: { type: "string" },
    concept: { type: "string" },
    strong: { type: "array", items: { type: "string" } },
    review: { type: "array", items: { type: "string" } },
    two_minute_review: { type: "array", items: { type: "string" } },
  },
  required: [
    "assessment",
    "feedback",
    "teaching_point",
    "concept",
    "strong",
    "review",
    "two_minute_review",
  ],
  additionalProperties: false,
};

const RAPID_FIRE_SCHEMA = {
  type: "object",
  properties: {
    questions: { type: "array", items: LIKELY_QUESTION_ITEM },
  },
  required: ["questions"],
  additionalProperties: false,
};

function isNonEmptyString(value) {
  return typeof value === "string" && value.trim().length > 0;
}

function isStringArray(value) {
  return Array.isArray(value) && value.every((item) => typeof item === "string");
}

function isQAArray(value) {
  return (
    Array.isArray(value) &&
    value.every(
      (item) =>
        item &&
        typeof item === "object" &&
        isNonEmptyString(item.question) &&
        isNonEmptyString(item.answer)
    )
  );
}

function validatePrep(obj) {
  if (!obj || typeof obj !== "object") {
    throw new Error("Prep response was not a JSON object.");
  }
  if (typeof obj.recognized !== "boolean") {
    throw new Error("Prep response missing required field: recognized");
  }
  const requiredStringFields = ["title", "case_summary"];
  for (const field of requiredStringFields) {
    if (!isNonEmptyString(obj[field])) {
      throw new Error(`Prep response missing required field: ${field}`);
    }
  }
  const requiredArrayFields = [
    "why_operating",
    "anatomy",
    "operation_overview",
    "things_to_watch",
    "complications",
    "must_know",
  ];
  for (const field of requiredArrayFields) {
    if (!isStringArray(obj[field]) || obj[field].length === 0) {
      throw new Error(`Prep response missing or invalid array field: ${field}`);
    }
  }
  if (!isQAArray(obj.likely_questions) || obj.likely_questions.length === 0) {
    throw new Error("Prep response missing or invalid likely_questions.");
  }
  return obj;
}

function validatePimpFirstQuestion(obj) {
  if (!obj || !isNonEmptyString(obj.question)) {
    throw new Error("Pimp Me response missing a question.");
  }
  return obj;
}

function validatePimpEval(obj) {
  if (!obj || typeof obj !== "object") {
    throw new Error("Pimp Me eval response was not a JSON object.");
  }
  if (!ASSESSMENT_ENUM.includes(obj.assessment)) {
    throw new Error("Pimp Me eval response has an invalid assessment.");
  }
  for (const field of ["feedback", "teaching_point", "concept", "next_question"]) {
    if (!isNonEmptyString(obj[field])) {
      throw new Error(`Pimp Me eval response missing required field: ${field}`);
    }
  }
  return obj;
}

function validatePimpFinalEval(obj) {
  if (!obj || typeof obj !== "object") {
    throw new Error("Pimp Me final eval response was not a JSON object.");
  }
  if (!ASSESSMENT_ENUM.includes(obj.assessment)) {
    throw new Error("Pimp Me final eval response has an invalid assessment.");
  }
  for (const field of ["feedback", "teaching_point", "concept"]) {
    if (!isNonEmptyString(obj[field])) {
      throw new Error(`Pimp Me final eval response missing required field: ${field}`);
    }
  }
  for (const field of ["strong", "review", "two_minute_review"]) {
    if (!isStringArray(obj[field])) {
      throw new Error(`Pimp Me final eval response missing or invalid field: ${field}`);
    }
  }
  return obj;
}

function validateRapidFire(obj) {
  if (!obj || !isQAArray(obj.questions) || obj.questions.length !== 5) {
    throw new Error("Rapid Fire response must contain exactly 5 question/answer pairs.");
  }
  return obj;
}

// Minimal, intentionally non-exhaustive PHI heuristic. Never over-engineer this —
// it exists to catch the obvious cases (spec §12), not to be a compliance tool.
const PHI_PATTERNS = [
  /\bmrn\b/i,
  /medical record number/i,
  /\bdob\b/i,
  /date of birth/i,
  /\bssn\b/i,
  /social security/i,
  /\b\d{3}-\d{2}-\d{4}\b/, // SSN-shaped
  /patient(?:'s)? name/i,
];

function containsLikelyPHI(text) {
  if (typeof text !== "string") return false;
  return PHI_PATTERNS.some((pattern) => pattern.test(text));
}

module.exports = {
  PREP_JSON_SCHEMA,
  PIMP_FIRST_QUESTION_SCHEMA,
  PIMP_EVAL_SCHEMA,
  PIMP_FINAL_EVAL_SCHEMA,
  RAPID_FIRE_SCHEMA,
  validatePrep,
  validatePimpFirstQuestion,
  validatePimpEval,
  validatePimpFinalEval,
  validateRapidFire,
  containsLikelyPHI,
};
