import Foundation

/// A case type from the server-side catalog (see backend/cloud/scrubPrep/caseTypes.js),
/// shown as a Home-screen quick-pick and (later) groupable by specialty.
struct CaseType: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let specialty: String
    let featured: Bool
}

/// Response shape from `listCaseTypes`.
struct CaseTypeCatalog: Codable {
    let caseTypes: [CaseType]
}

/// Display labels for known specialty keys. Falls back to a capitalized rendering of the
/// raw key for any specialty the backend adds before the client knows its label.
enum Specialty {
    private static let displayNames: [String: String] = [
        "general_surgery": "General Surgery",
        "cardiothoracic": "Cardiothoracic",
        "ent": "ENT",
        "urology": "Urology",
        "orthopedics": "Orthopedics",
    ]

    static func displayName(for key: String) -> String {
        displayNames[key] ?? key.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
