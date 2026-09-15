import Combine
import Foundation

/// Drives the Rapid Fire flow: fetch exactly 5 high-yield question/answer pairs once,
/// then step through them one at a time — reveal the answer, advance, repeat. Unlike
/// Pimp Me there's nothing to grade or persist; it's a fixed self-test the student can
/// simply run again (spec §9: "2 minutes before the OR", no lengthy explanations).
@MainActor
final class RapidFireViewModel: ObservableObject {
    let caseDescription: String
    let prep: ORPrep

    @Published private(set) var isLoading = true
    @Published private(set) var questions: [QAPair] = []
    @Published private(set) var currentIndex = 0
    @Published private(set) var isAnswerRevealed = false
    @Published var errorMessage: String?

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
                let result = try await service.generateRapidFire(caseDescription: caseDescription, prep: prep)
                questions = result.questions
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

    /// Runs through the same set of questions again from the top.
    func restart() {
        currentIndex = 0
        isAnswerRevealed = false
    }

    private func friendlyMessage(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription
            ?? "Scrub Prep wasn't able to generate your rapid fire review. Please try again."
    }
}
