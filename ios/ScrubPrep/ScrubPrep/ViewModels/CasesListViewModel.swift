import Foundation

/// Backs the full Cases list (`CasesListView`) — separate from `HomeViewModel`, which
/// only ever needs the 5 most recent. Backend-authoritative, so (unlike the SwiftData
/// `@Query` this replaces) loading is explicit and async.
@MainActor
@Observable
final class CasesListViewModel {
    private(set) var cases: [ScrubCase] = []
    private(set) var isLoading = true
    var errorMessage: String?

    private let historyStore: CaseHistoryStore

    init(service: ScrubPrepServicing? = nil) {
        // See HomeViewModel's init comment: resolved in the body, not as a default
        // parameter value, since ScrubPrepServiceFactory.make() is MainActor-isolated.
        let resolvedService = service ?? ScrubPrepServiceFactory.make()
        historyStore = CaseHistoryStore(service: resolvedService)
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            // Newest first by the date each row displays (`createdAt`). The backend's
            // updatedAt order doesn't match it — marking a case reviewed bumps updatedAt.
            cases = try await historyStore.listAll().sorted { $0.createdAt > $1.createdAt }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Scrub Prep wasn't able to load your cases. Please try again."
        }
        isLoading = false
    }

    func markReviewed(_ scrubCase: ScrubCase) async {
        try? await historyStore.markReviewed(scrubCase)
    }

    /// Swipe-to-delete — removes locally immediately so the list feels responsive, but
    /// only after the server confirms the delete succeeded.
    func delete(at offsets: IndexSet) {
        let targets = offsets.map { cases[$0] }
        Task {
            for target in targets {
                do {
                    try await historyStore.delete(target)
                    cases.removeAll { $0.id == target.id }
                } catch {
                    errorMessage = (error as? LocalizedError)?.errorDescription
                        ?? "Scrub Prep wasn't able to delete this case. Please try again."
                }
            }
        }
    }
}
