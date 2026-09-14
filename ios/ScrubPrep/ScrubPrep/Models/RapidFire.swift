import Foundation

/// Response shape from `generateRapidFire` — exactly 5 question/answer pairs.
struct RapidFireResult: Codable {
    let questions: [QAPair]
}
