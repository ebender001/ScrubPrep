import Foundation

/// Response shape from `generateRapidFire` — exactly 5 question/answer pairs.
/// `nonisolated`: see ORPrep's note — a ParseCloudable ReturnType crossing actor
/// boundaries on ParseSwift's background executor.
nonisolated struct RapidFireResult: Codable {
    let questions: [QAPair]
}
