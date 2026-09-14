import Foundation
import ParseSwift

// MARK: - Cloud Function request types
//
// Each conforms to ParseCloudable: `functionJobName` names the deployed Cloud Function
// (see backend/cloud/main.js) and every other stored property becomes a request parameter.

private struct GenerateScrubPrepRequest: ParseCloudable {
    typealias ReturnType = ORPrep
    var functionJobName = "generateScrubPrep"
    let caseDescription: String
}

private struct StartPimpSessionRequest: ParseCloudable {
    typealias ReturnType = PimpSessionStart
    var functionJobName = "startPimpSession"
    let caseDescription: String
    let prep: ORPrep
    let difficulty: PimpDifficulty
}

private struct AnswerPimpQuestionRequest: ParseCloudable {
    typealias ReturnType = PimpAnswerResult
    var functionJobName = "answerPimpQuestion"
    let sessionId: String
    let answer: String
}

private struct GenerateRapidFireRequest: ParseCloudable {
    typealias ReturnType = RapidFireResult
    var functionJobName = "generateRapidFire"
    let caseDescription: String
    let prep: ORPrep
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

    func generateRapidFire(caseDescription: String, prep: ORPrep) async throws -> RapidFireResult {
        try await run { try await GenerateRapidFireRequest(caseDescription: caseDescription, prep: prep).runFunction() }
    }

    /// Maps ParseError / networking failures onto the UI-facing error type (spec §20:
    /// never show raw backend errors to the student).
    private func run<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch let error as ParseError {
            if error.code == .connectionFailed {
                throw ScrubPrepError.network
            }
            throw ScrubPrepError.server
        } catch {
            throw ScrubPrepError.network
        }
    }
}
