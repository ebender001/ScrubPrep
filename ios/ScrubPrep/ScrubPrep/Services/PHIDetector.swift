import Foundation

/// On-device check for likely patient-identifying information, run before a case note
/// is saved so it never leaves the device. Covers the backend's label heuristic
/// (`PHI_PATTERNS` in backend/cloud/scrubPrep/schemas.js: "MRN", "DOB", SSNs) plus
/// specific dates, named facilities, and phone/email — identifiers a real note is likely
/// to contain. Still a safety net for obvious slips, not a guarantee: it can't recognize
/// personal names (surgery is full of eponyms), month/day-only dates like "9/20" (they
/// collide with "5/5 strength"), or descriptions like "45M in bed 12".
nonisolated enum PHIDetector {
    /// One kind of identifier found, with the exact text that matched (deduplicated,
    /// in order of first appearance).
    struct Finding: Equatable {
        let kind: String
        let matches: [String]
    }

    private static let month =
        #"(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)"#
    private static let dayOfMonth = #"(?:[12]\d|3[01]|0?[1-9])(?:st|nd|rd|th)?"#

    private static let patterns: [(kind: String, pattern: String, caseSensitive: Bool)] = [
        ("Medical record number", #"\bmrn\b|medical record number"#, false),
        ("Date of birth", #"\bdob\b|date of birth"#, false),
        (
            "Specific date",
            [
                // May 7 / Sept. 20th / May 7, 2026
                #"\b\#(month)\.?\s+\#(dayOfMonth)\b(?:,?\s+\d{4}\b)?"#,
                // 7 May / 20th of September 2026
                #"\b\#(dayOfMonth)\s+(?:of\s+)?\#(month)\b\.?(?:,?\s+\d{4}\b)?"#,
                // 5/7/2026, 05-07-26 — a year is required so "5/5 strength" isn't a date
                #"\b(?:0?[1-9]|1[0-2])[/-](?:[12]\d|3[01]|0?[1-9])[/-](?:\d{4}|\d{2})\b"#,
                // 2026-05-07
                #"\b\d{4}-(?:0?[1-9]|1[0-2])-(?:[12]\d|3[01]|0?[1-9])\b"#,
            ].joined(separator: "|"),
            false
        ),
        ("Social Security number", #"\bssn\b|social security|\b\d{3}-\d{2}-\d{4}\b"#, false),
        ("Phone number", #"(?:\(\d{3}\)\s*|\b\d{3}[-.\s])\d{3}[-.\s]\d{4}\b"#, false),
        ("Email address", #"\b[\w.+-]+@[\w-]+\.[\w.-]+\b"#, false),
        (
            "Facility name",
            // One to four capitalized words (or "St.") before a facility word — "Stanford
            // Hospital", "St. Mary's Medical Center". Case-sensitive so "the hospital" and
            // a sentence-initial "Hospital course" don't count.
            #"\b(?:(?:St\.|[A-Z][A-Za-z'’&-]*)\s+){1,4}(?:Hospital|Medical Cent(?:er|re)|Health Cent(?:er|re)|Clinic|Infirmary|Surgery Center|Surgical Center)\b"#,
            true
        ),
        ("Patient name", #"patient(?:'s|’s)? name"#, false),
    ]

    /// Findings grouped by kind, in the order kinds are listed above; empty if none.
    static func findings(in text: String) -> [Finding] {
        let range = NSRange(text.startIndex..., in: text)
        return patterns.compactMap { entry in
            guard let regex = try? NSRegularExpression(
                pattern: entry.pattern,
                options: entry.caseSensitive ? [] : .caseInsensitive
            ) else {
                return nil
            }
            var matches: [String] = []
            for result in regex.matches(in: text, range: range) {
                guard let matchRange = Range(result.range, in: text) else { continue }
                let match = String(text[matchRange])
                if !matches.contains(where: { $0.caseInsensitiveCompare(match) == .orderedSame }) {
                    matches.append(match)
                }
            }
            return matches.isEmpty ? nil : Finding(kind: entry.kind, matches: matches)
        }
    }
}
