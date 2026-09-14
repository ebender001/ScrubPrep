import Foundation
import SwiftData

/// A completed OR Prep, persisted locally via SwiftData (spec §11 — case history is
/// client-side for v1). Never more than one entry per (normalized) case description —
/// see CaseHistoryStore.addOrUpdate, which updates + re-dates an existing match instead
/// of inserting a duplicate.
@Model
final class ScrubCase {
    var id: UUID = UUID()
    var caseDescription: String = ""
    var normalizedDescription: String = ""
    var prep: ORPrep
    var createdAt: Date = Date()
    var lastReviewedAt: Date?

    init(caseDescription: String, prep: ORPrep, createdAt: Date = Date(), lastReviewedAt: Date? = nil) {
        self.id = UUID()
        self.caseDescription = caseDescription
        self.normalizedDescription = ScrubCase.normalize(caseDescription)
        self.prep = prep
        self.createdAt = createdAt
        self.lastReviewedAt = lastReviewedAt
    }

    static func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
