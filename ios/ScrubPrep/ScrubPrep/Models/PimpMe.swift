import Foundation

enum PimpDifficulty: String, Codable, CaseIterable, Identifiable {
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
/// Codable so a completed session's transcript can be persisted (see PimpMeSession).
struct PimpTurn: Identifiable, Hashable, Codable {
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
