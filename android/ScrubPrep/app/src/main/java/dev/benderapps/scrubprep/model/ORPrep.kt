package dev.benderapps.scrubprep.model

import org.json.JSONObject

/** A question/answer pair, used both in OR Prep's "likely questions" and Rapid Fire. */
data class QAPair(val question: String, val answer: String) {
    companion object {
        fun fromJson(json: JSONObject) = QAPair(json.getString("question"), json.getString("answer"))
    }

    fun toJson(): JSONObject = JSONObject().put("question", question).put("answer", answer)
}

/**
 * A verified reference for a prep's operation — a real StatPearls article the backend found
 * through NCBI and the AI chose from that real list (backend/cloud/scrubPrep/references.js).
 * Never AI-written; `url` is built from NCBI's own accession.
 */
data class PrepReference(val title: String, val source: String, val url: String) {
    companion object {
        fun fromJson(json: JSONObject) = PrepReference(
            json.getString("title"),
            json.getString("source"),
            json.getString("url"),
        )
    }

    fun toJson(): JSONObject = JSONObject().put("title", title).put("source", source).put("url", url)
}

/**
 * The structured OR Prep session returned by the `generateScrubPrep` Cloud Function.
 * Mirrors backend/cloud/scrubPrep/schemas.js's PREP_JSON_SCHEMA exactly (snake_case keys).
 */
data class ORPrep(
    val title: String,
    val caseSummary: String,
    val whyOperating: List<String>,
    val anatomy: List<String>,
    val operationOverview: List<String>,
    val thingsToWatch: List<String>,
    val complications: List<String>,
    val mustKnow: List<String>,
    val likelyQuestions: List<QAPair>,
    /**
     * `null` for preps generated before references existed, or whose lookup failed; empty
     * when nothing relevant was found. Either way the UI falls back to a search link.
     */
    val references: List<PrepReference>? = null,
) {
    companion object {
        fun fromJson(json: JSONObject) = ORPrep(
            title = json.getString("title"),
            caseSummary = json.optString("case_summary"),
            whyOperating = json.stringList("why_operating"),
            anatomy = json.stringList("anatomy"),
            operationOverview = json.stringList("operation_overview"),
            thingsToWatch = json.stringList("things_to_watch"),
            complications = json.stringList("complications"),
            mustKnow = json.stringList("must_know"),
            likelyQuestions = json.optJSONArray("likely_questions")?.mapObjects(QAPair::fromJson) ?: emptyList(),
            references = json.optJSONArray("references")?.mapObjects(PrepReference::fromJson),
        )
    }

    fun toJson(): JSONObject = JSONObject()
        .put("title", title)
        .put("case_summary", caseSummary)
        .put("why_operating", whyOperating.toJsonArray())
        .put("anatomy", anatomy.toJsonArray())
        .put("operation_overview", operationOverview.toJsonArray())
        .put("things_to_watch", thingsToWatch.toJsonArray())
        .put("complications", complications.toJsonArray())
        .put("must_know", mustKnow.toJsonArray())
        .put("likely_questions", likelyQuestions.toJsonArray { it.toJson() })
        .also { json -> references?.let { json.put("references", it.toJsonArray { ref -> ref.toJson() }) } }
}
