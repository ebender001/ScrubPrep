import Foundation

/// A specialty from the server-side catalog (see backend/cloud/scrubPrep/specialties.js),
/// shown as a filter row on the Home screen.
// `nonisolated`: see ORPrep's note — these cross actor boundaries as ParseCloudable
// ReturnTypes/nested payloads decoded on ParseSwift's background executor.
nonisolated struct Specialty: Codable, Identifiable {
    let id: String
    let name: String
    /// Backend-owned example shown in the case-entry field once this specialty is
    /// selected (e.g. "Lap chole for acute cholecystitis" for General Surgery) — the
    /// single source of truth lives in the `Specialty` Parse class, not client code.
    /// Optional/defaulted because `CaseType`'s embedded specialty (from `listCaseTypes`)
    /// only carries `id`/`name`, not this field.
    let exampleCaseDescription: String?

    init(id: String, name: String, exampleCaseDescription: String? = nil) {
        self.id = id
        self.name = name
        self.exampleCaseDescription = exampleCaseDescription
    }
}

extension Specialty: Equatable, Hashable {
    // Identity is the backend objectId alone — not all stored properties — since the same
    // specialty can arrive with different subsets of fields populated depending on which
    // endpoint embedded it (listSpecialties vs. CaseType.specialty from listCaseTypes).
    // Comparing every field would make those two representations compare unequal.
    static func == (lhs: Specialty, rhs: Specialty) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Response shape from `listSpecialties`.
nonisolated struct SpecialtyCatalog: Codable {
    let specialties: [Specialty]
}

extension Specialty {
    /// Shown before any specialty is selected, or if a selected specialty is missing its
    /// backend-provided example.
    static let defaultExampleCaseDescription = "Lap chole for symptomatic gallstones"

    /// `exampleCaseDescription` with the generic fallback applied — use this instead of
    /// the raw stored property when displaying an example.
    var displayedExampleCaseDescription: String {
        guard let text = exampleCaseDescription, !text.isEmpty else {
            return Specialty.defaultExampleCaseDescription
        }
        return text
    }
}

/// A case type from the server-side catalog (see backend/cloud/scrubPrep/caseTypes.js),
/// shown as a Home-screen quick-pick and filterable by specialty. `name` is the short/
/// colloquial chip label (e.g. "Lap Chole"); `fullName` is the proper clinical name
/// inserted into the case description field when the chip is tapped (e.g. "Laparoscopic
/// Cholecystectomy") — identical to `name` when there's no common abbreviation.
nonisolated struct CaseType: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let fullName: String
    let specialty: Specialty?
    let featured: Bool
}

/// Response shape from `listCaseTypes`.
nonisolated struct CaseTypeCatalog: Codable {
    let caseTypes: [CaseType]
}
