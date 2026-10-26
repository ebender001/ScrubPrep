package dev.benderapps.scrubprep.model

import org.json.JSONObject
import java.time.Instant
import java.util.UUID

enum class PimpDifficulty(val raw: String, val displayName: String, val subtitle: String) {
    Easy("easy", "Easy", "Foundational questions, more guidance."),
    Typical("typical", "Typical Attending", "Standard student-level quizzing."),
    Tough("tough", "Tough Attending", "Faster pace, follow-ups probe deeper.");

    companion object {
        fun fromRaw(raw: String) = entries.first { it.raw == raw }
    }
}

enum class PimpAssessment(val raw: String, val label: String) {
    Correct("correct", "Correct"),
    PartiallyCorrect("partially_correct", "Partially Correct"),
    Incorrect("incorrect", "Incorrect");

    companion object {
        fun fromRaw(raw: String) = entries.first { it.raw == raw }
    }
}

data class PimpProgress(val index: Int, val total: Int) {
    companion object {
        fun fromJson(json: JSONObject) = PimpProgress(json.getInt("index"), json.getInt("total"))
    }
}

/** Response shape from `startPimpSession`. */
data class PimpSessionStart(
    val sessionId: String,
    val question: String,
    val progress: PimpProgress,
    val done: Boolean,
) {
    companion object {
        fun fromJson(json: JSONObject) = PimpSessionStart(
            sessionId = json.getString("sessionId"),
            question = json.getString("question"),
            progress = PimpProgress.fromJson(json.getJSONObject("progress")),
            done = json.optBoolean("done"),
        )
    }
}

/** The end-of-session readiness summary, present on the final `answerPimpQuestion` response. */
data class PimpSummary(
    val strong: List<String>,
    val review: List<String>,
    val twoMinuteReview: List<String>,
) {
    companion object {
        fun fromJson(json: JSONObject) = PimpSummary(
            strong = json.stringList("strong"),
            review = json.stringList("review"),
            twoMinuteReview = json.stringList("twoMinuteReview"),
        )
    }

    fun toJson(): JSONObject = JSONObject()
        .put("strong", strong.toJsonArray())
        .put("review", review.toJsonArray())
        .put("twoMinuteReview", twoMinuteReview.toJsonArray())
}

/** Response shape from `answerPimpQuestion`. */
data class PimpAnswerResult(
    val sessionId: String,
    val assessment: PimpAssessment,
    val feedback: String,
    val teachingPoint: String,
    val nextQuestion: String?,
    val done: Boolean,
    val progress: PimpProgress,
    val summary: PimpSummary?,
) {
    companion object {
        fun fromJson(json: JSONObject) = PimpAnswerResult(
            sessionId = json.getString("sessionId"),
            assessment = PimpAssessment.fromRaw(json.getString("assessment")),
            feedback = json.getString("feedback"),
            teachingPoint = json.getString("teachingPoint"),
            nextQuestion = json.stringOrNull("nextQuestion"),
            done = json.optBoolean("done"),
            progress = PimpProgress.fromJson(json.getJSONObject("progress")),
            summary = json.optJSONObject("summary")?.let(PimpSummary::fromJson),
        )
    }
}

/** One completed turn in a Pimp Me session, kept client-side for display/history. */
data class PimpTurn(
    val id: String = UUID.randomUUID().toString(),
    val question: String,
    val answer: String,
    val assessment: PimpAssessment,
    val feedback: String,
    val teachingPoint: String,
) {
    companion object {
        fun fromJson(json: JSONObject) = PimpTurn(
            id = json.optString("id", UUID.randomUUID().toString()),
            question = json.getString("question"),
            answer = json.getString("answer"),
            assessment = PimpAssessment.fromRaw(json.getString("assessment")),
            feedback = json.getString("feedback"),
            teachingPoint = json.getString("teachingPoint"),
        )
    }

    fun toJson(): JSONObject = JSONObject()
        .put("id", id)
        .put("question", question)
        .put("answer", answer)
        .put("assessment", assessment.raw)
        .put("feedback", feedback)
        .put("teachingPoint", teachingPoint)
}

/**
 * A completed Pimp Me session for one (case, difficulty) pair, sourced from the backend's
 * `listPimpMeSessions`/`savePimpMeSession` Cloud Functions. At most one per (normalized
 * case description, difficulty) per account.
 */
data class PimpMeSession(
    val id: String,
    val caseDescription: String,
    val difficulty: PimpDifficulty,
    val transcript: List<PimpTurn>,
    val summary: PimpSummary,
    val completedAt: Instant,
) {
    companion object {
        fun fromJson(json: JSONObject) = PimpMeSession(
            id = json.getString("id"),
            caseDescription = json.getString("caseDescription"),
            difficulty = PimpDifficulty.fromRaw(json.getString("difficulty")),
            transcript = json.optJSONArray("transcript")?.mapObjects(PimpTurn::fromJson) ?: emptyList(),
            summary = PimpSummary.fromJson(json.getJSONObject("summary")),
            completedAt = parseInstant(json.optString("completedAt")),
        )
    }
}
