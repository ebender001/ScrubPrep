import Combine
import Foundation

/// Drives an interactive Pimp Me session: difficulty selection, then one question at a
/// time, feedback after each answer, and a final readiness summary.
@MainActor
final class PimpMeViewModel: ObservableObject {
    enum Phase: Equatable {
        case pickingDifficulty
        case starting
        /// Showing a question, awaiting the student's answer.
        case answering
        /// Showing feedback for the answer just submitted, before advancing.
        case reviewingFeedback
        case completed(PimpSummary)

        static func == (lhs: Phase, rhs: Phase) -> Bool {
            switch (lhs, rhs) {
            case (.pickingDifficulty, .pickingDifficulty),
                 (.starting, .starting),
                 (.answering, .answering),
                 (.reviewingFeedback, .reviewingFeedback):
                return true
            case let (.completed(a), .completed(b)):
                return a == b
            default:
                return false
            }
        }
    }

    let caseDescription: String
    let prep: ORPrep

    @Published var difficulty: PimpDifficulty = .typical
    @Published var phase: Phase = .pickingDifficulty
    @Published var currentQuestion: String?
    @Published var progress: PimpProgress?
    @Published var answerText: String = ""
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    /// The question/answer/feedback just submitted — shown during `.reviewingFeedback`.
    @Published private(set) var lastTurn: PimpTurn?
    /// Every completed turn this session, oldest first.
    @Published private(set) var history: [PimpTurn] = []

    private let service: ScrubPrepServicing
    private var sessionId: String?

    init(caseDescription: String, prep: ORPrep, service: ScrubPrepServicing? = nil) {
        self.caseDescription = caseDescription
        self.prep = prep
        self.service = service ?? ScrubPrepServiceFactory.make()
    }

    func start() {
        phase = .starting
        errorMessage = nil
        Task {
            do {
                let result = try await service.startPimpSession(
                    caseDescription: caseDescription,
                    prep: prep,
                    difficulty: difficulty
                )
                sessionId = result.sessionId
                currentQuestion = result.question
                progress = result.progress
                phase = .answering
            } catch {
                phase = .pickingDifficulty
                errorMessage = friendlyMessage(for: error)
            }
        }
    }

    func submitAnswer() {
        let trimmed = answerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let sessionId, let question = currentQuestion, !trimmed.isEmpty else { return }

        isSubmitting = true
        errorMessage = nil
        Task {
            do {
                let result = try await service.answerPimpQuestion(sessionId: sessionId, answer: trimmed)
                isSubmitting = false
                progress = result.progress
                answerText = ""

                let turn = PimpTurn(
                    question: question,
                    answer: trimmed,
                    assessment: result.assessment,
                    feedback: result.feedback,
                    teachingPoint: result.teachingPoint
                )
                lastTurn = turn
                history.append(turn)

                if result.done, let summary = result.summary {
                    phase = .completed(summary)
                } else {
                    currentQuestion = result.nextQuestion
                    phase = .reviewingFeedback
                }
            } catch {
                isSubmitting = false
                errorMessage = friendlyMessage(for: error)
            }
        }
    }

    /// Advances from the feedback shown after an answer to the next question.
    func continueToNextQuestion() {
        phase = .answering
    }

    private func friendlyMessage(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription
            ?? "Scrub Prep wasn't able to continue this session. Please try again."
    }
}
