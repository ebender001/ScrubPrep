import Foundation

/// A completed OR Prep, kept in local case history (spec: case history is client-side
/// for v1 — see backend/README.md's "Notes / TODOs for later phases").
struct ScrubCase: Codable, Identifiable, Hashable {
    let id: UUID
    let caseDescription: String
    let prep: ORPrep
    let createdAt: Date
    var lastReviewedAt: Date?

    init(caseDescription: String, prep: ORPrep, createdAt: Date = Date(), lastReviewedAt: Date? = nil) {
        self.id = UUID()
        self.caseDescription = caseDescription
        self.prep = prep
        self.createdAt = createdAt
        self.lastReviewedAt = lastReviewedAt
    }
}
