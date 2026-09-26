import Foundation
import ParseSwift

// Custom Parse error code backend/cloud/main.js uses for "that wasn't a real procedure" —
// see UNRECOGNIZED_CASE_ERROR_CODE there. Kept in sync manually; there's no shared schema
// between the JS and Swift sides for this.
private let unrecognizedCaseErrorCode = 4001

// MARK: - Cloud Function request types
//
// Each conforms to ParseCloudable: `functionJobName` names the deployed Cloud Function
// (see backend/cloud/main.js) and every other stored property becomes a request parameter.
//
// `nonisolated`: this project defaults new types to MainActor isolation (see ORPrep's
// equivalent note), but ParseCloudable's `runFunction()` encodes/decodes on ParseSwift's
// own background executor — a MainActor-isolated conformance can't be used from there
// under strict concurrency checking ("Main actor-isolated conformance ... cannot be used
// in @concurrent context; this is an error in the Swift 6 language mode").

nonisolated private struct GenerateScrubPrepRequest: ParseCloudable {
    typealias ReturnType = ORPrep
    var functionJobName = "generateScrubPrep"
    let caseDescription: String
}

nonisolated private struct StartPimpSessionRequest: ParseCloudable {
    typealias ReturnType = PimpSessionStart
    var functionJobName = "startPimpSession"
    let caseDescription: String
    let prep: ORPrep
    let difficulty: PimpDifficulty
}

nonisolated private struct AnswerPimpQuestionRequest: ParseCloudable {
    typealias ReturnType = PimpAnswerResult
    var functionJobName = "answerPimpQuestion"
    let sessionId: String
    let answer: String
}

nonisolated private struct GenerateRapidFireRequest: ParseCloudable {
    typealias ReturnType = RapidFireResult
    var functionJobName = "generateRapidFire"
    let caseDescription: String
    let prep: ORPrep
    let previousQuestions: [String]
}

nonisolated private struct ListCaseTypesRequest: ParseCloudable {
    typealias ReturnType = CaseTypeCatalog
    var functionJobName = "listCaseTypes"
}

nonisolated private struct ListSpecialtiesRequest: ParseCloudable {
    typealias ReturnType = SpecialtyCatalog
    var functionJobName = "listSpecialties"
}

nonisolated private struct CaseCatalog: Codable {
    let cases: [ScrubCase]
}

nonisolated private struct SaveCaseResult: Codable {
    let `case`: ScrubCase
}

nonisolated private struct SuccessResult: Codable {
    let success: Bool
}

nonisolated private struct PimpMeSessionCatalog: Codable {
    let sessions: [PimpMeSession]
}

nonisolated private struct SavePimpMeSessionResult: Codable {
    let session: PimpMeSession
}

nonisolated private struct ListCasesRequest: ParseCloudable {
    typealias ReturnType = CaseCatalog
    var functionJobName = "listCases"
}

nonisolated private struct SaveCaseRequest: ParseCloudable {
    typealias ReturnType = SaveCaseResult
    var functionJobName = "saveCase"
    let caseDescription: String
    let prep: ORPrep
    let specialtyId: String?
}

nonisolated private struct MarkCaseReviewedRequest: ParseCloudable {
    typealias ReturnType = SuccessResult
    var functionJobName = "markCaseReviewed"
    let caseId: String
}

nonisolated private struct DeleteCaseRequest: ParseCloudable {
    typealias ReturnType = SuccessResult
    var functionJobName = "deleteCase"
    let caseId: String
}

nonisolated private struct ListPimpMeSessionsRequest: ParseCloudable {
    typealias ReturnType = PimpMeSessionCatalog
    var functionJobName = "listPimpMeSessions"
    let caseDescription: String
}

nonisolated private struct SavePimpMeSessionRequest: ParseCloudable {
    typealias ReturnType = SavePimpMeSessionResult
    var functionJobName = "savePimpMeSession"
    let caseDescription: String
    let difficulty: PimpDifficulty
    let transcript: [PimpTurn]
    let summary: PimpSummary
}

/// Talks to the real Back4App Cloud Functions via the Parse Swift SDK.
/// All OpenAI calls happen server-side — this type never sees an OpenAI key (spec §4).
struct ParseScrubPrepService: ScrubPrepServicing {
    func generatePrep(caseDescription: String) async throws -> ORPrep {
        try await run { try await GenerateScrubPrepRequest(caseDescription: caseDescription).runFunction() }
    }

    func startPimpSession(caseDescription: String, prep: ORPrep, difficulty: PimpDifficulty) async throws -> PimpSessionStart {
        try await run {
            try await StartPimpSessionRequest(caseDescription: caseDescription, prep: prep, difficulty: difficulty).runFunction()
        }
    }

    func answerPimpQuestion(sessionId: String, answer: String) async throws -> PimpAnswerResult {
        try await run { try await AnswerPimpQuestionRequest(sessionId: sessionId, answer: answer).runFunction() }
    }

    func generateRapidFire(caseDescription: String, prep: ORPrep, previousQuestions: [String]) async throws -> RapidFireResult {
        try await run {
            try await GenerateRapidFireRequest(caseDescription: caseDescription, prep: prep, previousQuestions: previousQuestions).runFunction()
        }
    }

    func listCaseTypes() async throws -> [CaseType] {
        try await run { try await ListCaseTypesRequest().runFunction().caseTypes }
    }

    func listSpecialties() async throws -> [Specialty] {
        try await run { try await ListSpecialtiesRequest().runFunction().specialties }
    }

    func listCases() async throws -> [ScrubCase] {
        try await run { try await ListCasesRequest().runFunction().cases }
    }

    func saveCase(caseDescription: String, prep: ORPrep, specialtyId: String?) async throws -> ScrubCase {
        try await run {
            try await SaveCaseRequest(caseDescription: caseDescription, prep: prep, specialtyId: specialtyId)
                .runFunction().case
        }
    }

    func markCaseReviewed(caseId: String) async throws {
        try await run { try await MarkCaseReviewedRequest(caseId: caseId).runFunction() }
    }

    func deleteCase(caseId: String) async throws {
        try await run { try await DeleteCaseRequest(caseId: caseId).runFunction() }
    }

    func listPimpMeSessions(caseDescription: String) async throws -> [PimpMeSession] {
        try await run { try await ListPimpMeSessionsRequest(caseDescription: caseDescription).runFunction().sessions }
    }

    func savePimpMeSession(
        caseDescription: String,
        difficulty: PimpDifficulty,
        transcript: [PimpTurn],
        summary: PimpSummary
    ) async throws -> PimpMeSession {
        try await run {
            try await SavePimpMeSessionRequest(
                caseDescription: caseDescription,
                difficulty: difficulty,
                transcript: transcript,
                summary: summary
            ).runFunction().session
        }
    }

    /// Maps ParseError / networking failures onto the UI-facing error type (spec §20:
    /// never show raw backend errors to the student). `.unrecognizedCase` is the
    /// deliberate exception — its message is shown verbatim.
    @discardableResult
    private func run<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch let error as ParseError {
            if error.code == .connectionFailed {
                throw ScrubPrepError.network
            }
            if error.code == .other, error.otherCode == unrecognizedCaseErrorCode {
                throw ScrubPrepError.unrecognizedCase(message: error.message)
            }
            // A stale session token (e.g. restored from the Keychain after the app was
            // deleted and reinstalled — Keychain items survive app deletion, unlike
            // UserDefaults) makes Parse Server reject EVERY request carrying it, even
            // calls to functions that don't themselves require sign-in. Without this,
            // the app would sit signed-in-but-broken forever (every fetch silently
            // empty) with no way to recover short of manually signing out. AuthViewModel
            // observes this to force a sign-out back to SignInView.
            if error.code == .invalidSessionToken {
                NotificationCenter.default.post(name: .invalidSessionDetected, object: nil)
            }
            throw ScrubPrepError.server
        } catch {
            throw ScrubPrepError.network
        }
    }
}

extension Notification.Name {
    static let invalidSessionDetected = Notification.Name("invalidSessionDetected")
}
