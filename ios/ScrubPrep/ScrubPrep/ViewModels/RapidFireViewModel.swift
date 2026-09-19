import Foundation

/// Drives the Rapid Fire flow: fetch exactly 5 high-yield question/answer pairs, then
/// step through them one at a time — reveal the answer, advance, repeat. Unlike Pimp Me
/// there's nothing to grade or persist; "Go Again" generates a fresh set of 5 rather than
/// replaying the same ones (spec §9: "2 minutes before the OR", no lengthy explanations).
@MainActor
@Observable
final class RapidFireViewModel {
    /// Caps the whole review (across every "Go Again" round) at 10 questions total —
    /// this is meant to be a 2-minute pre-op refresher, not an unbounded quiz.
    static let maxTotalQuestions = 10

    let caseDescription: String
    let prep: ORPrep

    private(set) var isLoading = true
    private(set) var questions: [QAPair] = []
    private(set) var currentIndex = 0
    private(set) var isAnswerRevealed = false
    var errorMessage: String?

    /// Every question asked across all rounds this session (including the current one,
    /// once loaded) — sent back on the next "Go Again" so a fresh set doesn't just repeat
    /// the same five questions.
    private var askedQuestions: [String] = []

    private let service: ScrubPrepServicing

    init(caseDescription: String, prep: ORPrep, service: ScrubPrepServicing? = nil) {
        self.caseDescription = caseDescription
        self.prep = prep
        self.service = service ?? ScrubPrepServiceFactory.make()
    }

    var currentQuestion: QAPair? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    var isComplete: Bool {
        !questions.isEmpty && currentIndex >= questions.count
    }

    var isLastQuestion: Bool {
        currentIndex == questions.count - 1
    }

    /// False once the total across all rounds has hit maxTotalQuestions — gates the
    /// "Go Again" button on the completed screen.
    var canGoAgain: Bool {
        askedQuestions.count < Self.maxTotalQuestions
    }

    /// Idempotent once questions are loaded, so a repeated `.onAppear` (e.g. during a
    /// `@ViewBuilder` phase switch) doesn't re-fetch a fresh set out from under the
    /// student mid-review. Safe to call again after a failed attempt, since `questions`
    /// is still empty in that case — that's how the "Try Again" button retries.
    func load() {
        guard questions.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let result = try await service.generateRapidFire(
                    caseDescription: caseDescription,
                    prep: prep,
                    previousQuestions: askedQuestions
                )
                questions = result.questions
                askedQuestions.append(contentsOf: result.questions.map(\.question))
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = friendlyMessage(for: error)
            }
        }
    }

    func revealAnswer() {
        isAnswerRevealed = true
    }

    func advance() {
        isAnswerRevealed = false
        currentIndex += 1
    }

    /// Starts a new round with a freshly-generated set of 5 questions, steering away from
    /// every question already asked this session — not the same set replayed from the top.
    /// No-ops once maxTotalQuestions has been reached (the view hides this button by then,
    /// via canGoAgain — this guard is just a backstop).
    func restart() {
        guard canGoAgain else { return }
        currentIndex = 0
        isAnswerRevealed = false
        questions = []
        load()
    }

    private func friendlyMessage(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription
            ?? "Scrub Prep wasn't able to generate your rapid fire review. Please try again."
    }
}
