import Foundation

/// Sort choices for the Cases list's sort/filter menu. Raw values are persisted via
/// `@AppStorage` in `CasesListView`, so don't rename them.
enum CaseSortOrder: String, CaseIterable, Identifiable {
    case newestFirst
    case oldestFirst
    case nameAscending

    var id: Self { self }

    var title: String {
        switch self {
        case .newestFirst: "Newest first"
        case .oldestFirst: "Oldest first"
        case .nameAscending: "Name A–Z"
        }
    }
}

/// Backs the full Cases list (`CasesListView`) — separate from `HomeViewModel`, which
/// only ever needs the 5 most recent. Backend-authoritative, so (unlike the SwiftData
/// `@Query` this replaces) loading is explicit and async.
@MainActor
@Observable
final class CasesListViewModel {
    private(set) var cases: [ScrubCase] = []
    private(set) var isLoading = true
    var errorMessage: String?

    var searchText = ""
    /// `Specialty.id` to filter by, or `nil` for all specialties. Not persisted — filters
    /// reset on launch; only the sort order is remembered.
    var specialtyFilter: String?

    private let historyStore: CaseHistoryStore

    init(service: ScrubPrepServicing? = nil) {
        // See HomeViewModel's init comment: resolved in the body, not as a default
        // parameter value, since ScrubPrepServiceFactory.make() is MainActor-isolated.
        let resolvedService = service ?? ScrubPrepServiceFactory.make()
        historyStore = CaseHistoryStore(service: resolvedService)
    }

    /// Specialties that actually appear in the user's saved cases (not the full catalog),
    /// alphabetized to match the Home screen's specialty menu.
    var availableSpecialties: [Specialty] {
        Set(cases.compactMap(\.specialty))
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var isFiltering: Bool { specialtyFilter != nil }

    var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The cases to display — filtered by search text and specialty, then sorted. Derived
    /// on read; `cases` itself is never reordered or trimmed by this.
    func visibleCases(sortedBy sortOrder: CaseSortOrder) -> [ScrubCase] {
        let query = trimmedSearchText
        let filtered = cases.filter { scrubCase in
            if let specialtyFilter, scrubCase.specialty?.id != specialtyFilter {
                return false
            }
            guard !query.isEmpty else { return true }
            // localizedStandardContains is case- and diacritic-insensitive.
            return scrubCase.prep.title.localizedStandardContains(query)
                || scrubCase.caseDescription.localizedStandardContains(query)
        }
        switch sortOrder {
        case .newestFirst:
            return filtered.sorted { $0.createdAt > $1.createdAt }
        case .oldestFirst:
            return filtered.sorted { $0.createdAt < $1.createdAt }
        case .nameAscending:
            return filtered.sorted { $0.prep.title.localizedStandardCompare($1.prep.title) == .orderedAscending }
        }
    }

    func clearFilters() {
        specialtyFilter = nil
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            cases = try await historyStore.listAll()
            dropStaleSpecialtyFilter()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Scrub Prep wasn't able to load your cases. Please try again."
        }
        isLoading = false
    }

    func markReviewed(_ scrubCase: ScrubCase) async {
        try? await historyStore.markReviewed(scrubCase)
    }

    /// Swipe-to-delete — takes the cases themselves (not row offsets) since the displayed
    /// rows are a filtered/sorted view of `cases`. Removes locally only after the server
    /// confirms the delete succeeded.
    func delete(_ targets: [ScrubCase]) {
        Task {
            for target in targets {
                do {
                    try await historyStore.delete(target)
                    cases.removeAll { $0.id == target.id }
                    dropStaleSpecialtyFilter()
                } catch {
                    errorMessage = (error as? LocalizedError)?.errorDescription
                        ?? "Scrub Prep wasn't able to delete this case. Please try again."
                }
            }
        }
    }

    /// Clears the specialty filter once no remaining case has that specialty, so the
    /// menu's picker never points at an option it no longer lists.
    private func dropStaleSpecialtyFilter() {
        guard let specialtyFilter else { return }
        if !cases.contains(where: { $0.specialty?.id == specialtyFilter }) {
            self.specialtyFilter = nil
        }
    }
}
