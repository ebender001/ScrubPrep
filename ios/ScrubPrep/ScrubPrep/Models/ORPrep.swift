import Foundation

/// A question/answer pair, used both in OR Prep's "likely questions" and Rapid Fire.
/// `nonisolated`: this project defaults new types to MainActor isolation, but plain
/// Codable data crossing actor boundaries (network decoding, SwiftData's background
/// persistence machinery) needs its conformances usable from a nonisolated context.
nonisolated struct QAPair: Codable, Hashable, Identifiable {
    let question: String
    let answer: String

    var id: String { question }
}

/// The structured OR Prep session returned by the `generateScrubPrep` Cloud Function.
/// Mirrors backend/cloud/scrubPrep/schemas.js's PREP_JSON_SCHEMA exactly.
/// `nonisolated`: see QAPair's note — required for SwiftData to persist this as a
/// stored property on ScrubCase without a Swift 6 mode isolation error.
nonisolated struct ORPrep: Codable, Hashable {
    let title: String
    let caseSummary: String
    let whyOperating: [String]
    let anatomy: [String]
    let operationOverview: [String]
    let thingsToWatch: [String]
    let complications: [String]
    let mustKnow: [String]
    let likelyQuestions: [QAPair]

    enum CodingKeys: String, CodingKey {
        case title
        case caseSummary = "case_summary"
        case whyOperating = "why_operating"
        case anatomy
        case operationOverview = "operation_overview"
        case thingsToWatch = "things_to_watch"
        case complications
        case mustKnow = "must_know"
        case likelyQuestions = "likely_questions"
    }

    /// Defensive fallback only — used if a stored ScrubCase's JSON blob ever fails to
    /// decode (shouldn't happen in practice; see ScrubCase.prep).
    static let empty = ORPrep(
        title: "Untitled Case",
        caseSummary: "",
        whyOperating: [],
        anatomy: [],
        operationOverview: [],
        thingsToWatch: [],
        complications: [],
        mustKnow: [],
        likelyQuestions: []
    )
}
