import Foundation

/// Wraps a `ScrubPrepServicing` and caches `generatePrep` results in-memory for the
/// lifetime of the app process, keyed by normalized case description. Avoids a repeat
/// network/OpenAI call when the student navigates Home -> Prep -> back -> Prepare Me
/// again with the same case. Cache is intentionally temporary (in-memory only, not
/// persisted) — it clears on relaunch, unlike the permanent case history.
///
/// Pimp Me / Rapid Fire aren't cached: each session/round should generate fresh
/// questions rather than repeat the same ones.
final class CachingScrubPrepService: ScrubPrepServicing {
    private let wrapped: ScrubPrepServicing
    private var prepCache: [String: ORPrep] = [:]

    init(wrapping service: ScrubPrepServicing) {
        self.wrapped = service
    }

    func generatePrep(caseDescription: String) async throws -> ORPrep {
        let key = Self.normalize(caseDescription)
        if let cached = prepCache[key] {
            return cached
        }
        let prep = try await wrapped.generatePrep(caseDescription: caseDescription)
        prepCache[key] = prep
        return prep
    }

    func startPimpSession(caseDescription: String, prep: ORPrep, difficulty: PimpDifficulty) async throws -> PimpSessionStart {
        try await wrapped.startPimpSession(caseDescription: caseDescription, prep: prep, difficulty: difficulty)
    }

    func answerPimpQuestion(sessionId: String, answer: String) async throws -> PimpAnswerResult {
        try await wrapped.answerPimpQuestion(sessionId: sessionId, answer: answer)
    }

    func generateRapidFire(caseDescription: String, prep: ORPrep) async throws -> RapidFireResult {
        try await wrapped.generateRapidFire(caseDescription: caseDescription, prep: prep)
    }

    private static func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
