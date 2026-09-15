import Foundation

/// Thin wrapper around `ScrubPrepServicing`'s Pimp Me session Cloud Functions — the
/// backend is the single source of truth for a user's completed sessions, not the
/// device. Mirrors the shape this type had when it wrapped a SwiftData `ModelContext`
/// (same method names), now async since every call is a network round-trip.
@MainActor
final class PimpMeSessionStore {
    private let service: ScrubPrepServicing

    init(service: ScrubPrepServicing) {
        self.service = service
    }

    /// The completed session for this (case, difficulty) pair, if one exists.
    func find(caseDescription: String, difficulty: PimpDifficulty) async throws -> PimpMeSession? {
        let sessions = try await service.listPimpMeSessions(caseDescription: caseDescription)
        return sessions.first { $0.difficulty == difficulty }
    }

    /// Every difficulty already completed for this case — used to gate the difficulty
    /// picker (a completed difficulty is locked from restarting; tapping it reviews the
    /// transcript instead, so the student progresses to a different difficulty).
    func completedDifficulties(forCaseDescription caseDescription: String) async throws -> Set<PimpDifficulty> {
        let sessions = try await service.listPimpMeSessions(caseDescription: caseDescription)
        return Set(sessions.map(\.difficulty))
    }

    /// Inserts a new completed session, or overwrites the existing one for this exact
    /// (case, difficulty) pair — enforced server-side; see
    /// backend/cloud/scrubPrep/pimpMeSessions.js. Never duplicates.
    @discardableResult
    func save(
        caseDescription: String,
        difficulty: PimpDifficulty,
        transcript: [PimpTurn],
        summary: PimpSummary
    ) async throws -> PimpMeSession {
        try await service.savePimpMeSession(
            caseDescription: caseDescription,
            difficulty: difficulty,
            transcript: transcript,
            summary: summary
        )
    }
}
