import Foundation

// `nonisolated`: this project defaults new types to MainActor isolation, but these are
// plain Codable/Hashable payloads that cross actor boundaries — as ParseCloudable
// ReturnTypes decoded on ParseSwift's background executor, and as stored properties
// whose own Hashable/Equatable conformances get pulled into a ParseCloudable request
// struct's synthesized Hashable conformance (ParseCloudable itself requires Hashable).
// A MainActor-isolated conformance can't be used from a nonisolated/concurrent context
// under strict concurrency checking (see ORPrep's equivalent note).

nonisolated enum PimpDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy
    case typical
    case tough

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .typical: return "Typical Attending"
        case .tough: return "Tough Attending"
        }
    }

    var subtitle: String {
        switch self {
        case .easy: return "Foundational questions, more guidance."
        case .typical: return "Standard student-level pimping."
        case .tough: return "Faster pace, follow-ups probe deeper."
        }
    }
}

nonisolated enum PimpAssessment: String, Codable {
    case correct
    case partiallyCorrect = "partially_correct"
    case incorrect
}

nonisolated struct PimpProgress: Codable, Hashable {
    let index: Int
    let total: Int
}

/// Response shape from `startPimpSession`.
nonisolated struct PimpSessionStart: Codable {
    let sessionId: String
    let question: String
    let progress: PimpProgress
    let done: Bool
}

/// The end-of-session readiness summary, present on the final `answerPimpQuestion` response.
nonisolated struct PimpSummary: Codable, Hashable {
    let strong: [String]
    let review: [String]
    let twoMinuteReview: [String]
}

/// Response shape from `answerPimpQuestion`.
nonisolated struct PimpAnswerResult: Codable {
    let sessionId: String
    let assessment: PimpAssessment
    let feedback: String
    let teachingPoint: String
    let nextQuestion: String?
    let done: Bool
    let progress: PimpProgress
    let summary: PimpSummary?
}

/// One completed turn in a Pimp Me session, kept client-side for display/history.
/// Codable so a completed session's transcript can be persisted (see PimpMeSession).
nonisolated struct PimpTurn: Identifiable, Hashable, Codable {
    let id: UUID
    let question: String
    let answer: String
    let assessment: PimpAssessment
    let feedback: String
    let teachingPoint: String

    init(id: UUID = UUID(), question: String, answer: String, assessment: PimpAssessment, feedback: String, teachingPoint: String) {
        self.id = id
        self.question = question
        self.answer = answer
        self.assessment = assessment
        self.feedback = feedback
        self.teachingPoint = teachingPoint
    }
}
