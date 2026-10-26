package dev.benderapps.scrubprep.data

/**
 * On-device check for likely patient-identifying information, run before a case note is
 * saved so it never leaves the device. Covers the backend's label heuristic (`PHI_PATTERNS`
 * in backend/cloud/scrubPrep/schemas.js: "MRN", "DOB", SSNs) plus specific dates, named
 * facilities, and phone/email. Still a safety net for obvious slips, not a guarantee: it
 * can't recognize personal names (surgery is full of eponyms), month/day-only dates like
 * "9/20" (they collide with "5/5 strength"), or descriptions like "45M in bed 12".
 */
object PHIDetector {
    /** One kind of identifier found, with the exact text that matched (deduplicated). */
    data class Finding(val kind: String, val matches: List<String>)

    private const val MONTH =
        "(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)"
    private const val DAY_OF_MONTH = "(?:[12]\\d|3[01]|0?[1-9])(?:st|nd|rd|th)?"

    private class Entry(val kind: String, val pattern: String, val caseSensitive: Boolean) {
        val regex = Regex(pattern, if (caseSensitive) emptySet() else setOf(RegexOption.IGNORE_CASE))
    }

    private val entries = listOf(
        Entry("Medical record number", "\\bmrn\\b|medical record number", false),
        Entry("Date of birth", "\\bdob\\b|date of birth", false),
        Entry(
            "Specific date",
            listOf(
                // May 7 / Sept. 20th / May 7, 2026
                "\\b$MONTH\\.?\\s+$DAY_OF_MONTH\\b(?:,?\\s+\\d{4}\\b)?",
                // 7 May / 20th of September 2026
                "\\b$DAY_OF_MONTH\\s+(?:of\\s+)?$MONTH\\b\\.?(?:,?\\s+\\d{4}\\b)?",
                // 5/7/2026, 05-07-26 — a year is required so "5/5 strength" isn't a date
                "\\b(?:0?[1-9]|1[0-2])[/-](?:[12]\\d|3[01]|0?[1-9])[/-](?:\\d{4}|\\d{2})\\b",
                // 2026-05-07
                "\\b\\d{4}-(?:0?[1-9]|1[0-2])-(?:[12]\\d|3[01]|0?[1-9])\\b",
            ).joinToString("|"),
            false,
        ),
        Entry("Social Security number", "\\bssn\\b|social security|\\b\\d{3}-\\d{2}-\\d{4}\\b", false),
        Entry("Phone number", "(?:\\(\\d{3}\\)\\s*|\\b\\d{3}[-.\\s])\\d{3}[-.\\s]\\d{4}\\b", false),
        Entry("Email address", "\\b[\\w.+-]+@[\\w-]+\\.[\\w.-]+\\b", false),
        Entry(
            "Facility name",
            // One to four capitalized words (or "St.") before a facility word — "Stanford
            // Hospital", "St. Mary's Medical Center". Case-sensitive so "the hospital" and
            // a sentence-initial "Hospital course" don't count.
            "\\b(?:(?:St\\.|[A-Z][A-Za-z'\u2019&-]*)\\s+){1,4}(?:Hospital|Medical Cent(?:er|re)|Health Cent(?:er|re)|Clinic|Infirmary|Surgery Center|Surgical Center)\\b",
            true,
        ),
        Entry("Patient name", "patient(?:'s|\u2019s)? name", false),
    )

    /** Findings grouped by kind, in the order kinds are listed above; empty if none. */
    fun findings(text: String): List<Finding> = entries.mapNotNull { entry ->
        val matches = mutableListOf<String>()
        for (result in entry.regex.findAll(text)) {
            val match = result.value
            if (matches.none { it.equals(match, ignoreCase = true) }) matches += match
        }
        if (matches.isEmpty()) null else Finding(entry.kind, matches)
    }
}
