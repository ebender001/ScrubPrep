import Foundation

/// Thin wrapper around `ScrubPrepServicing`'s Case-related Cloud Functions — the backend
/// is the single source of truth for a user's saved Cases, not the device. Mirrors the
/// shape this type had when it wrapped a SwiftData `ModelContext` (same method names),
/// now async since every call is a network round-trip.
@MainActor
final class CaseHistoryStore {
    private let service: ScrubPrepServicing

    init(service: ScrubPrepServicing) {
        self.service = service
    }

    /// Every case saved for the signed-in user, most recently updated first.
    func listAll() async throws -> [ScrubCase] {
        try await service.listCases()
    }

    /// Looks up an already-prepared case by (normalized) description — used by
    /// HomeViewModel.resolvePrep to skip a network/OpenAI hit entirely when this exact
    /// case was already prepared.
    func find(caseDescription: String) async throws -> ScrubCase? {
        let normalized = ScrubCase.normalize(caseDescription)
        let all = try await service.listCases()
        return all.first { ScrubCase.normalize($0.caseDescription) == normalized }
    }

    /// Inserts a new case, or — if the same (normalized) case description was already
    /// saved — updates and re-dates that existing entry instead (enforced server-side;
    /// see backend/cloud/scrubPrep/cases.js). Never duplicates.
    @discardableResult
    func addOrUpdate(caseDescription: String, prep: ORPrep, specialty: Specialty?) async throws -> ScrubCase {
        try await service.saveCase(caseDescription: caseDescription, prep: prep, specialtyId: specialty?.id)
    }

    func markReviewed(_ scrubCase: ScrubCase) async throws {
        try await service.markCaseReviewed(caseId: scrubCase.id)
    }

    func delete(_ scrubCase: ScrubCase) async throws {
        try await service.deleteCase(caseId: scrubCase.id)
    }
}
