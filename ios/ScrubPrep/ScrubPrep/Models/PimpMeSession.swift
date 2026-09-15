import Foundation

/// A completed Pimp Me session for one (case, difficulty) pair, sourced from the
/// backend's `listPimpMeSessions`/`savePimpMeSession` Cloud Functions — the backend is
/// the single source of truth, not the device (see `PimpMeSessionStore`). At most one
/// per (normalized case description, difficulty) per account.
/// `nonisolated`: see ORPrep's note — crosses actor boundaries as a ParseCloudable
/// ReturnType/nested payload decoded on ParseSwift's background executor.
nonisolated struct PimpMeSession: Codable, Identifiable, Hashable {
    let id: String
    let caseDescription: String
    let difficulty: PimpDifficulty
    let transcript: [PimpTurn]
    let summary: PimpSummary
    private let completedAtRaw: String

    enum CodingKeys: String, CodingKey {
        case id, caseDescription, difficulty, transcript, summary
        case completedAtRaw = "completedAt"
    }

    // See ScrubCase's isoFormatter comment — same reasoning applies here, including
    // `nonisolated(unsafe)` for the same not-Sendable-but-read-only-safe reason.
    nonisolated(unsafe) private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    var completedAt: Date { Self.isoFormatter.date(from: completedAtRaw) ?? Date() }

    // See ScrubCase's equivalent initializer comment — the synthesized memberwise init
    // would be `private` since completedAtRaw is private.
    init(id: String, caseDescription: String, difficulty: PimpDifficulty, transcript: [PimpTurn], summary: PimpSummary, completedAt: Date) {
        self.id = id
        self.caseDescription = caseDescription
        self.difficulty = difficulty
        self.transcript = transcript
        self.summary = summary
        self.completedAtRaw = Self.isoFormatter.string(from: completedAt)
    }
}
