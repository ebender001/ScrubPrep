import Foundation

/// A question/answer pair, used both in OR Prep's "likely questions" and Rapid Fire.
struct QAPair: Codable, Hashable, Identifiable {
    let question: String
    let answer: String

    var id: String { question }
}

/// The structured OR Prep session returned by the `generateScrubPrep` Cloud Function.
/// Mirrors backend/cloud/scrubPrep/schemas.js's PREP_JSON_SCHEMA exactly.
struct ORPrep: Codable, Hashable {
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
}
