import Foundation
import SwiftData

/// Thin helper around a SwiftData `ModelContext` for OR Prep case history writes.
/// Reads happen directly via `@Query` in views; this centralizes the "never
/// duplicate a case" and "mark reviewed" write logic (spec §11).
@MainActor
final class CaseHistoryStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Looks up an already-prepared case by (normalized) description — the on-device,
    /// cross-launch source of truth for "have we already generated this case?" (used by
    /// HomeViewModel.prepareCase to skip a network/OpenAI hit entirely when found).
    func find(caseDescription: String) -> ScrubCase? {
        let normalized = ScrubCase.normalize(caseDescription)
        let descriptor = FetchDescriptor<ScrubCase>(
            predicate: #Predicate { $0.normalizedDescription == normalized }
        )
        return try? modelContext.fetch(descriptor).first
    }

    /// Inserts a new case, or — if the same (normalized) case description was already
    /// prepared — updates and re-dates that existing entry instead. Never duplicates
    /// (e.g. regenerating "Lap Chole" always results in exactly one "Lap Chole" entry).
    @discardableResult
    func addOrUpdate(caseDescription: String, prep: ORPrep) -> ScrubCase {
        let normalized = ScrubCase.normalize(caseDescription)
        let descriptor = FetchDescriptor<ScrubCase>(
            predicate: #Predicate { $0.normalizedDescription == normalized }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.caseDescription = caseDescription
            existing.prep = prep
            existing.createdAt = Date()
            existing.lastReviewedAt = nil
            save()
            return existing
        }
        let scrubCase = ScrubCase(caseDescription: caseDescription, prep: prep)
        modelContext.insert(scrubCase)
        save()
        return scrubCase
    }

    func markReviewed(_ scrubCase: ScrubCase) {
        scrubCase.lastReviewedAt = Date()
        save()
    }

    func delete(_ scrubCase: ScrubCase) {
        modelContext.delete(scrubCase)
        save()
    }

    func delete(at offsets: IndexSet, in cases: [ScrubCase]) {
        for index in offsets {
            modelContext.delete(cases[index])
        }
        save()
    }

    private func save() {
        try? modelContext.save()
    }
}
