import Foundation

/// A saved Case (completed OR Prep), sourced from the backend's `listCases`/`saveCase`
/// Cloud Functions — the backend is the single source of truth, not the device (see
/// `CaseHistoryStore`). At most one per (normalized) case description per account.
/// `nonisolated`: see ORPrep's note — crosses actor boundaries as a ParseCloudable
/// ReturnType/nested payload decoded on ParseSwift's background executor.
nonisolated struct ScrubCase: Codable, Identifiable, Hashable {
    let id: String
    let caseDescription: String
    let prep: ORPrep
    /// The specialty selected when the case was prepared (`id`/`name` only). `nil` for
    /// cases saved before the backend recorded it, or prepared with none selected.
    let specialty: Specialty?
    private let createdAtRaw: String
    private let updatedAtRaw: String
    private let lastReviewedAtRaw: String?

    enum CodingKeys: String, CodingKey {
        case id, caseDescription, prep, specialty
        case createdAtRaw = "createdAt"
        case updatedAtRaw = "updatedAt"
        case lastReviewedAtRaw = "lastReviewedAt"
    }

    // Dates arrive as plain ISO8601 strings (see backend/cloud/scrubPrep/cases.js) rather
    // than relying on however ParseCloudable's decoder would otherwise handle a native
    // Date — parsed defensively here instead of trusting an untested decoding path.
    // `nonisolated(unsafe)`: ISO8601DateFormatter isn't Sendable, but this instance is
    // only ever used for read-only string(from:)/date(from:) calls after configuration,
    // which is safe to share across threads in practice.
    nonisolated(unsafe) private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    var createdAt: Date { Self.isoFormatter.date(from: createdAtRaw) ?? Date() }
    var updatedAt: Date { Self.isoFormatter.date(from: updatedAtRaw) ?? Date() }
    var lastReviewedAt: Date? { lastReviewedAtRaw.flatMap(Self.isoFormatter.date) }

    // The compiler-synthesized memberwise init would be `private` (it takes the least
    // accessible level of any stored property, and the raw date strings are private) —
    // this is the constructor other files (MockScrubPrepService, previews) actually use.
    init(
        id: String,
        caseDescription: String,
        prep: ORPrep,
        specialty: Specialty? = nil,
        createdAt: Date,
        updatedAt: Date,
        lastReviewedAt: Date?
    ) {
        self.id = id
        self.caseDescription = caseDescription
        self.prep = prep
        self.specialty = specialty
        self.createdAtRaw = Self.isoFormatter.string(from: createdAt)
        self.updatedAtRaw = Self.isoFormatter.string(from: updatedAt)
        self.lastReviewedAtRaw = lastReviewedAt.map(Self.isoFormatter.string)
    }

    static func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
