import Combine
import Foundation

/// Drives an interactive Pimp Me session: difficulty selection, then one question at a
/// time, feedback after each answer, and a final readiness summary. Each difficulty can
/// only be completed once per case — once done it's locked from restarting and instead
/// shows its saved transcript (see PimpMeSessionStore).
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
        /// Reviewing a previously-completed difficulty's saved transcript (read-only).
        case reviewingTranscript(difficulty: PimpDifficulty, transcript: [PimpTurn], summary: PimpSummary)

        static func == (lhs: Phase, rhs: Phase) -> Bool {
            switch (lhs, rhs) {
            case (.pickingDifficulty, .pickingDifficulty),
                 (.starting, .starting),
                 (.answering, .answering),
                 (.reviewingFeedback, .reviewingFeedback):
                return true
            case let (.completed(a), .completed(b)):
                return a == b
            case let (.reviewingTranscript(d1, _, s1), .reviewingTranscript(d2, _, s2)):
                return d1 == d2 && s1 == s2
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
    /// Difficulties already completed for this case, across all sessions ever taken —
    /// drives the "locked, tap to review" state on the difficulty picker.
    @Published private(set) var completedDifficulties: Set<PimpDifficulty> = []

    private let service: ScrubPrepServicing
    private var sessionStore: PimpMeSessionStore?
    private var sessionId: String?

    init(caseDescription: String, prep: ORPrep, service: ScrubPrepServicing? = nil) {
        self.caseDescription = caseDescription
        self.prep = prep
        self.service = service ?? ScrubPrepServiceFactory.make()
    }

    /// Wires up SwiftData persistence. Called once the view's `modelContext` is available
    /// (not yet resolved at `init` time — see HomeViewModel's analogous historyStore note).
    func attachSessionStore(_ store: PimpMeSessionStore) {
        guard sessionStore == nil else { return }
        sessionStore = store
        completedDifficulties = store.completedDifficulties(forCaseDescription: caseDescription)

        // Default selection should land on something startable, not a level already done.
        if completedDifficulties.contains(difficulty) {
            if let firstRemaining = PimpDifficulty.allCases.first(where: { !completedDifficulties.contains($0) }) {
                difficulty = firstRemaining
            }
        }
    }

    /// Tapping a difficulty row: if it's already completed, show its saved transcript;
    /// otherwise just select it as the level to start.
    func selectDifficulty(_ level: PimpDifficulty) {
        if completedDifficulties.contains(level) {
            showTranscript(for: level)
        } else {
            difficulty = level
        }
    }

    private func showTranscript(for level: PimpDifficulty) {
        guard let session = sessionStore?.find(caseDescription: caseDescription, difficulty: level) else { return }
        phase = .reviewingTranscript(difficulty: level, transcript: session.transcript, summary: session.summary)
    }

    /// Returns from a transcript review or a just-finished summary to the difficulty
    /// picker, so the student can progress to a harder or easier level.
    func backToDifficultyPicker() {
        phase = .pickingDifficulty
    }

    func start() {
        guard !completedDifficulties.contains(difficulty) else { return }
        phase = .starting
        errorMessage = nil
        history = []
        lastTurn = nil
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
                    sessionStore?.save(
                        caseDescription: caseDescription,
                        difficulty: difficulty,
                        transcript: history,
                        summary: summary
                    )
                    completedDifficulties.insert(difficulty)
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
