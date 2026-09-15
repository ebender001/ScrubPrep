import Foundation
import SwiftData

/// A completed Pimp Me session for one (case, difficulty) pair, persisted locally via
/// SwiftData so it can be reviewed later instead of being lost once the interactive view
/// is dismissed. At most one per (normalized case description, difficulty) — see
/// PimpMeSessionStore.save, which overwrites rather than duplicates.
///
/// Stores the transcript/summary as encoded JSON blobs rather than letting SwiftData
/// decompose them into composite attributes — the same reasoning as ScrubCase.prepData:
/// this project has already been burned once by a SwiftData/Codable property-name
/// mismatch crash, so nested Codable types are round-tripped through Data here instead.
@Model
final class PimpMeSession {
    var id: UUID = UUID()
    var caseDescription: String = ""
    var normalizedDescription: String = ""
    var difficultyRawValue: String = PimpDifficulty.typical.rawValue
    var completedAt: Date = Date()

    private var transcriptData: Data = Data()
    private var summaryData: Data = Data()

    var difficulty: PimpDifficulty {
        get { PimpDifficulty(rawValue: difficultyRawValue) ?? .typical }
        set { difficultyRawValue = newValue.rawValue }
    }

    var transcript: [PimpTurn] {
        get { (try? JSONDecoder().decode([PimpTurn].self, from: transcriptData)) ?? [] }
        set { transcriptData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var summary: PimpSummary {
        get {
            (try? JSONDecoder().decode(PimpSummary.self, from: summaryData))
                ?? PimpSummary(strong: [], review: [], twoMinuteReview: [])
        }
        set { summaryData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    init(caseDescription: String, difficulty: PimpDifficulty, transcript: [PimpTurn], summary: PimpSummary, completedAt: Date = Date()) {
        self.id = UUID()
        self.caseDescription = caseDescription
        self.normalizedDescription = ScrubCase.normalize(caseDescription)
        self.difficultyRawValue = difficulty.rawValue
        self.completedAt = completedAt
        self.transcriptData = (try? JSONEncoder().encode(transcript)) ?? Data()
        self.summaryData = (try? JSONEncoder().encode(summary)) ?? Data()
    }
}
