import Foundation
import SwiftData

/// Thin helper around a SwiftData `ModelContext` for completed Pimp Me sessions —
/// mirrors CaseHistoryStore's shape/conventions.
@MainActor
final class PimpMeSessionStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// The completed session for this (case, difficulty) pair, if one exists.
    func find(caseDescription: String, difficulty: PimpDifficulty) -> PimpMeSession? {
        let normalized = ScrubCase.normalize(caseDescription)
        let difficultyRaw = difficulty.rawValue
        let descriptor = FetchDescriptor<PimpMeSession>(
            predicate: #Predicate { $0.normalizedDescription == normalized && $0.difficultyRawValue == difficultyRaw }
        )
        return try? modelContext.fetch(descriptor).first
    }

    /// Every difficulty already completed for this case — used to gate the difficulty
    /// picker (spec: a completed difficulty is locked from restarting; tapping it reviews
    /// the transcript instead, so the student progresses to a different difficulty).
    func completedDifficulties(forCaseDescription caseDescription: String) -> Set<PimpDifficulty> {
        let normalized = ScrubCase.normalize(caseDescription)
        let descriptor = FetchDescriptor<PimpMeSession>(
            predicate: #Predicate { $0.normalizedDescription == normalized }
        )
        let sessions = (try? modelContext.fetch(descriptor)) ?? []
        return Set(sessions.map(\.difficulty))
    }

    /// Inserts a new completed session, or overwrites the existing one for this exact
    /// (case, difficulty) pair — never duplicates.
    @discardableResult
    func save(caseDescription: String, difficulty: PimpDifficulty, transcript: [PimpTurn], summary: PimpSummary) -> PimpMeSession {
        if let existing = find(caseDescription: caseDescription, difficulty: difficulty) {
            existing.transcript = transcript
            existing.summary = summary
            existing.completedAt = Date()
            save()
            return existing
        }
        let session = PimpMeSession(caseDescription: caseDescription, difficulty: difficulty, transcript: transcript, summary: summary)
        modelContext.insert(session)
        save()
        return session
    }

    private func save() {
        try? modelContext.save()
    }
}
