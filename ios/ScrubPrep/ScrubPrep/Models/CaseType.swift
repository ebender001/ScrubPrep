import Foundation

/// A specialty from the server-side catalog (see backend/cloud/scrubPrep/specialties.js),
/// shown as a filter row on the Home screen.
struct Specialty: Codable, Identifiable, Hashable {
    let id: String
    let name: String
}

/// Response shape from `listSpecialties`.
struct SpecialtyCatalog: Codable {
    let specialties: [Specialty]
}

/// A case type from the server-side catalog (see backend/cloud/scrubPrep/caseTypes.js),
/// shown as a Home-screen quick-pick and filterable by specialty. `name` is the short/
/// colloquial chip label (e.g. "Lap Chole"); `fullName` is the proper clinical name
/// inserted into the case description field when the chip is tapped (e.g. "Laparoscopic
/// Cholecystectomy") — identical to `name` when there's no common abbreviation.
struct CaseType: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let fullName: String
    let specialty: Specialty?
    let featured: Bool
}

/// Response shape from `listCaseTypes`.
struct CaseTypeCatalog: Codable {
    let caseTypes: [CaseType]
}
