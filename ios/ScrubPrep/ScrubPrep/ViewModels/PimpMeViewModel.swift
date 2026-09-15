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
    /// Set once the final question's feedback comes back, while that feedback is still
    /// being shown — the session only actually completes (and gets saved) once the
    /// student taps through past it. Lets the last question's feedback card display
    /// like every other, instead of jumping straight to the summary.
    @Published private(set) var pendingSummary: PimpSummary?
    /// Difficulties already completed for this case, across all sessions ever taken —
    /// drives the "locked, tap to review" state on the difficulty picker.
    @Published private(set) var completedDifficulties: Set<PimpDifficulty> = []
    /// True until the initial fetch of completed difficulties finishes — the difficulty
    /// picker waits for this so it doesn't flash "everything unlocked" for a moment
    /// before locking the ones already completed.
    @Published private(set) var isLoadingCompletedDifficulties = true

    private let service: ScrubPrepServicing
    private let sessionStore: PimpMeSessionStore
    private var sessionId: String?

    init(caseDescription: String, prep: ORPrep, service: ScrubPrepServicing? = nil) {
        let resolvedService = service ?? ScrubPrepServiceFactory.make()
        self.caseDescription = caseDescription
        self.prep = prep
        self.service = resolvedService
        self.sessionStore = PimpMeSessionStore(service: resolvedService)
        Task { await self.loadCompletedDifficulties() }
    }

    private func loadCompletedDifficulties() async {
        if let fetched = try? await sessionStore.completedDifficulties(forCaseDescription: caseDescription) {
            completedDifficulties = fetched
            // Default selection should land on something startable, not a level already done.
            if completedDifficulties.contains(difficulty),
               let firstRemaining = PimpDifficulty.allCases.first(where: { !completedDifficulties.contains($0) }) {
                difficulty = firstRemaining
            }
        }
        isLoadingCompletedDifficulties = false
    }

    /// Tapping a difficulty row: if it's already completed, show its saved transcript;
    /// otherwise just select it as the level to start.
    func selectDifficulty(_ level: PimpDifficulty) {
        if completedDifficulties.contains(level) {
            Task { await showTranscript(for: level) }
        } else {
            difficulty = level
        }
    }

    private func showTranscript(for level: PimpDifficulty) async {
        guard let session = try? await sessionStore.find(caseDescription: caseDescription, difficulty: level) else { return }
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
                    // Show this last turn's feedback first, same as any other question —
                    // completion (and the save below) happens on continueToNextQuestion().
                    pendingSummary = summary
                    phase = .reviewingFeedback
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

    /// True while showing the final question's feedback, before the student has tapped
    /// through to the summary — drives the "See Summary" vs "Next Question" button label.
    var isFinalFeedback: Bool {
        pendingSummary != nil
    }

    /// Advances from the feedback shown after an answer to the next question, or — if
    /// this was the final question — completes the session. The summary shows
    /// immediately rather than waiting on the save — it's a best-effort background
    /// persist (same "don't block the primary flow on a decorative write" reasoning as
    /// markCaseReviewed elsewhere), so a network hiccup here doesn't stall the student.
    func continueToNextQuestion() {
        if let summary = pendingSummary {
            phase = .completed(summary)
            completedDifficulties.insert(difficulty)
            pendingSummary = nil
            let completedTranscript = history
            let completedDifficultyLevel = difficulty
            Task {
                _ = try? await sessionStore.save(
                    caseDescription: caseDescription,
                    difficulty: completedDifficultyLevel,
                    transcript: completedTranscript,
                    summary: summary
                )
            }
        } else {
            phase = .answering
        }
    }

    private func friendlyMessage(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription
            ?? "Scrub Prep wasn't able to continue this session. Please try again."
    }
}
