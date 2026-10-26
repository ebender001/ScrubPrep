package dev.benderapps.scrubprep.model

import org.json.JSONObject
import java.time.Instant

/**
 * A saved Case (completed OR Prep), sourced from the backend's `listCases`/`saveCase`
 * Cloud Functions — the backend is the single source of truth, not the device. At most one
 * per (normalized) case description per account.
 */
data class ScrubCase(
    val id: String,
    val caseDescription: String,
    val prep: ORPrep,
    /** The specialty selected when the case was prepared; `null` for older cases. */
    val specialty: Specialty?,
    /** The student's own free-text notes ("My Notes"); `null` and "" mean the same. */
    val notes: String?,
    val createdAt: Instant,
    val updatedAt: Instant,
    val lastReviewedAt: Instant?,
) {
    val hasNotes: Boolean get() = !notes.isNullOrBlank()

    companion object {
        fun normalize(text: String) = text.trim().lowercase()

        fun fromJson(json: JSONObject) = ScrubCase(
            id = json.getString("id"),
            caseDescription = json.getString("caseDescription"),
            prep = ORPrep.fromJson(json.getJSONObject("prep")),
            specialty = json.optJSONObject("specialty")?.let(Specialty::fromJson),
            notes = json.stringOrNull("notes"),
            createdAt = parseInstant(json.optString("createdAt")),
            updatedAt = parseInstant(json.optString("updatedAt")),
            lastReviewedAt = json.stringOrNull("lastReviewedAt")?.let(::parseInstant),
        )
    }
}

/** ISO8601 string from the backend (cases.js); falls back to now rather than failing a list. */
internal fun parseInstant(text: String): Instant =
    runCatching { Instant.parse(text) }.getOrDefault(Instant.now())
