import Foundation

/// A question/answer pair, used both in OR Prep's "likely questions" and Rapid Fire.
/// `nonisolated`: this project defaults new types to MainActor isolation, but plain
/// Codable data crossing actor boundaries (network decoding) needs its conformances
/// usable from a nonisolated context.
nonisolated struct QAPair: Codable, Hashable, Identifiable {
    let question: String
    let answer: String

    var id: String { question }
}

/// A verified reference for a prep's operation — a real StatPearls article the backend
/// found through NCBI and the AI chose from that real list (backend/cloud/scrubPrep/
/// references.js). Never AI-written; `url` is built from NCBI's own accession.
/// `nonisolated`: see QAPair's note.
nonisolated struct PrepReference: Codable, Hashable, Identifiable {
    let title: String
    let source: String
    let url: URL

    var id: URL { url }
}

/// The structured OR Prep session returned by the `generateScrubPrep` Cloud Function.
/// Mirrors backend/cloud/scrubPrep/schemas.js's PREP_JSON_SCHEMA exactly.
/// `nonisolated`: see QAPair's note.
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
    /// `nil` for preps generated before references existed, or whose lookup failed; empty
    /// when nothing relevant was found. Either way the UI falls back to a search link.
    var references: [PrepReference]? = nil

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
        case references
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
