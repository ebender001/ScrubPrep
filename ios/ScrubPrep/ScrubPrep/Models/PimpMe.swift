import Foundation

enum PimpDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy
    case typical
    case tough
    case merciless

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .typical: return "Typical Attending"
        case .tough: return "Tough Attending"
        case .merciless: return "Merciless"
        }
    }

    var subtitle: String {
        switch self {
        case .easy: return "Foundational questions, more guidance."
        case .typical: return "Standard student-level pimping."
        case .tough: return "Faster pace, more follow-ups."
        case .merciless: return "Rapid-fire follow-ups. Still respectful."
        }
    }
}

enum PimpAssessment: String, Codable {
    case correct
    case partiallyCorrect = "partially_correct"
    case incorrect
}

struct PimpProgress: Codable, Hashable {
    let index: Int
    let total: Int
}

/// Response shape from `startPimpSession`.
struct PimpSessionStart: Codable {
    let sessionId: String
    let question: String
    let progress: PimpProgress
    let done: Bool
}

/// The end-of-session readiness summary, present on the final `answerPimpQuestion` response.
struct PimpSummary: Codable, Hashable {
    let strong: [String]
    let review: [String]
    let twoMinuteReview: [String]
}

/// Response shape from `answerPimpQuestion`.
struct PimpAnswerResult: Codable {
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
struct PimpTurn: Identifiable, Hashable {
    let id = UUID()
    let question: String
    let answer: String
    let assessment: PimpAssessment
    let feedback: String
    let teachingPoint: String
}
