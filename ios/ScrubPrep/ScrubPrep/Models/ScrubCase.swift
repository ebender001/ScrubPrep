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
    var createdAt: Date = Date()
    var lastReviewedAt: Date?

    // Stored as raw JSON rather than letting SwiftData decompose ORPrep into a
    // "composite attribute": SwiftData reflects over ORPrep's Swift property names
    // (e.g. `whyOperating`), but ORPrep's custom CodingKeys make Codable actually
    // encode/decode snake_case keys (`why_operating`) to match the backend's JSON —
    // that mismatch crashed SwiftData at runtime ("unknown property why_operating").
    // Encoding it ourselves sidesteps that entirely.
    private var prepData: Data = Data()

    var prep: ORPrep {
        get {
            (try? JSONDecoder().decode(ORPrep.self, from: prepData)) ?? .empty
        }
        set {
            prepData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    init(caseDescription: String, prep: ORPrep, createdAt: Date = Date(), lastReviewedAt: Date? = nil) {
        self.id = UUID()
        self.caseDescription = caseDescription
        self.normalizedDescription = ScrubCase.normalize(caseDescription)
        self.prepData = (try? JSONEncoder().encode(prep)) ?? Data()
        self.createdAt = createdAt
        self.lastReviewedAt = lastReviewedAt
    }

    static func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
