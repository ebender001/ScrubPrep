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

extension Specialty {
    /// A specialty-appropriate example shown in the case-entry card before the student has
    /// typed anything (Home screen). Keyed by name (the only stable, human-meaningful
    /// identifier — `id` is a backend-generated objectId). Add new specialties here as the
    /// catalog grows; falls back to a generic example for any specialty not yet listed.
    private static let exampleCaseDescriptionsByName: [String: String] = [
        "General Surgery": "Lap chole for acute cholecystitis",
        "Cardiac Surgery": "CABG \u{00D7}3 for multivessel CAD",
        "Thoracic Surgery": "VATS right upper lobectomy for lung cancer",
        "ENT": "Tonsillectomy for recurrent tonsillitis",
        "Urology": "TURP for BPH with urinary retention",
        "Orthopedics": "Total knee arthroplasty for end-stage osteoarthritis",
        "Vascular Surgery": "CEA for symptomatic carotid stenosis",
    ]

    static let defaultExampleCaseDescription = "Lap chole for symptomatic gallstones"

    var exampleCaseDescription: String {
        Specialty.exampleCaseDescriptionsByName[name] ?? Specialty.defaultExampleCaseDescription
    }
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
