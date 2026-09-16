import Foundation

/// Abstracts OR Prep / Pimp Me / Rapid Fire generation so view models don't care whether
/// they're talking to the real Back4App backend or bundled mock data.
protocol ScrubPrepServicing {
    func generatePrep(caseDescription: String) async throws -> ORPrep
    func startPimpSession(caseDescription: String, prep: ORPrep, difficulty: PimpDifficulty) async throws -> PimpSessionStart
    func answerPimpQuestion(sessionId: String, answer: String) async throws -> PimpAnswerResult
    func generateRapidFire(caseDescription: String, prep: ORPrep, previousQuestions: [String]) async throws -> RapidFireResult
    func listCaseTypes() async throws -> [CaseType]
    func listSpecialties() async throws -> [Specialty]

    // Cases and Pimp Me sessions are backend-authoritative (not stored on the device) —
    // every one of these requires a signed-in user server-side.
    func listCases() async throws -> [ScrubCase]
    func saveCase(caseDescription: String, prep: ORPrep) async throws -> ScrubCase
    func markCaseReviewed(caseId: String) async throws
    func deleteCase(caseId: String) async throws
    func listPimpMeSessions(caseDescription: String) async throws -> [PimpMeSession]
    func savePimpMeSession(
        caseDescription: String,
        difficulty: PimpDifficulty,
        transcript: [PimpTurn],
        summary: PimpSummary
    ) async throws -> PimpMeSession

    // Subscription/paywall — see backend/cloud/scrubPrep/subscriptions.js. The backend is
    // the only source of truth for both; these just read/report it, never decide it.
    func getAccessStatus() async throws -> AccessStatus
    func syncSubscriptionStatus(_ report: ReportedSubscriptionStatus) async throws -> AccessStatus
}

/// Errors surfaced to the UI. Kept generic and friendly per spec §20 — never show raw
/// backend/network errors to the student. `.unrecognizedCase` is the one deliberate
/// exception: it carries the backend's own (randomly-picked, witty) message verbatim,
/// since that message *is* the point — see backend/cloud/main.js's
/// UNRECOGNIZED_CASE_MESSAGES. `.subscriptionRequired` is the other deliberate exception —
/// it's never shown as an error message at all; HomeViewModel catches it specifically to
/// show the paywall instead (see backend's SUBSCRIPTION_REQUIRED_ERROR_CODE, 4002).
enum ScrubPrepError: LocalizedError {
    case network
    case server
    case invalidResponse
    case unrecognizedCase(message: String)
    case subscriptionRequired

    var errorDescription: String? {
        switch self {
        case .network:
            return "Check your connection and try again."
        case .server, .invalidResponse:
            return "Scrub Prep wasn't able to generate your preparation session. Please try again."
        case .unrecognizedCase(let message):
            return message
        case .subscriptionRequired:
            return "A subscription is required to prepare another case."
        }
    }
}

enum ScrubPrepServiceFactory {
    static func make() -> ScrubPrepServicing {
        AppConfig.useMockData ? MockScrubPrepService() : ParseScrubPrepService()
    }
}
