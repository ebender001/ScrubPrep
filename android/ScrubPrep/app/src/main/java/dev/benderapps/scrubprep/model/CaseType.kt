package dev.benderapps.scrubprep.model

import org.json.JSONObject

/**
 * A specialty from the server-side catalog (backend/cloud/scrubPrep/specialties.js), shown
 * as a filter menu on the Home screen. Identity is the backend objectId alone — the same
 * specialty can arrive with different subsets of fields depending on which endpoint
 * embedded it (listSpecialties vs. CaseType.specialty from listCaseTypes).
 */
class Specialty(
    val id: String,
    val name: String,
    /**
     * Backend-owned example shown in the case-entry field once this specialty is selected
     * (e.g. "Lap chole for acute cholecystitis" for General Surgery).
     */
    val exampleCaseDescription: String? = null,
) {
    override fun equals(other: Any?) = other is Specialty && other.id == id
    override fun hashCode() = id.hashCode()

    /** `exampleCaseDescription` with the generic fallback applied. */
    val displayedExampleCaseDescription: String
        get() = exampleCaseDescription?.takeIf { it.isNotEmpty() } ?: DEFAULT_EXAMPLE_CASE_DESCRIPTION

    fun toJson(): JSONObject = JSONObject()
        .put("id", id)
        .put("name", name)
        .also { json -> exampleCaseDescription?.let { json.put("exampleCaseDescription", it) } }

    companion object {
        const val DEFAULT_EXAMPLE_CASE_DESCRIPTION = "Lap chole for symptomatic gallstones"

        fun fromJson(json: JSONObject) = Specialty(
            id = json.getString("id"),
            name = json.getString("name"),
            exampleCaseDescription = json.stringOrNull("exampleCaseDescription"),
        )
    }
}

/**
 * A case type from the server-side catalog (backend/cloud/scrubPrep/caseTypes.js), shown as
 * a Home-screen quick-pick. `name` is the short chip label (e.g. "Lap Chole"); `fullName` is
 * the proper clinical name inserted into the case description when the chip is tapped.
 */
data class CaseType(
    val name: String,
    val fullName: String,
    val specialty: Specialty?,
    val featured: Boolean,
) {
    companion object {
        fun fromJson(json: JSONObject) = CaseType(
            name = json.getString("name"),
            fullName = json.optString("fullName", json.getString("name")),
            specialty = json.optJSONObject("specialty")?.let(Specialty::fromJson),
            featured = json.optBoolean("featured"),
        )
    }
}
