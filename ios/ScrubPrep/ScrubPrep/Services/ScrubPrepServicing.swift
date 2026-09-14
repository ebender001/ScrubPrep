import Foundation

/// Abstracts OR Prep / Pimp Me / Rapid Fire generation so view models don't care whether
/// they're talking to the real Back4App backend or bundled mock data.
protocol ScrubPrepServicing {
    func generatePrep(caseDescription: String) async throws -> ORPrep
    func startPimpSession(caseDescription: String, prep: ORPrep, difficulty: PimpDifficulty) async throws -> PimpSessionStart
    func answerPimpQuestion(sessionId: String, answer: String) async throws -> PimpAnswerResult
    func generateRapidFire(caseDescription: String, prep: ORPrep) async throws -> RapidFireResult
    func listCaseTypes() async throws -> [CaseType]
    func listSpecialties() async throws -> [Specialty]
}

/// Errors surfaced to the UI. Kept generic and friendly per spec §20 — never show raw
/// backend/network errors to the student. `.unrecognizedCase` is the one deliberate
/// exception: it carries the backend's own (randomly-picked, witty) message verbatim,
/// since that message *is* the point — see backend/cloud/main.js's
/// UNRECOGNIZED_CASE_MESSAGES.
enum ScrubPrepError: LocalizedError {
    case network
    case server
    case invalidResponse
    case unrecognizedCase(message: String)

    var errorDescription: String? {
        switch self {
        case .network:
            return "Check your connection and try again."
        case .server, .invalidResponse:
            return "Scrub Prep wasn't able to generate your preparation session. Please try again."
        case .unrecognizedCase(let message):
            return message
        }
    }
}

enum ScrubPrepServiceFactory {
    static func make() -> ScrubPrepServicing {
        AppConfig.useMockData ? MockScrubPrepService() : ParseScrubPrepService()
    }
}
