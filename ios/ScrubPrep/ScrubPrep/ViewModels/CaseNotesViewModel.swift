import Foundation

/// Backs the My Notes sheet (`CaseNotesSheet`). The prep screen only knows the case
/// description, not the saved case, so the case (and its current notes) is looked up by
/// description when the sheet opens.
@MainActor
@Observable
final class CaseNotesViewModel {
    enum LoadState {
        case loading
        case loaded
        /// No saved case matches — e.g. the save after Prepare Me failed silently.
        case notSaved
        case failed
    }

    private(set) var loadState: LoadState = .loading
    private(set) var isSaving = false
    var draft = ""
    var errorMessage: String?

    private let caseDescription: String
    private let historyStore: CaseHistoryStore
    private var scrubCase: ScrubCase?
    private var savedNotes = ""

    init(caseDescription: String, service: ScrubPrepServicing? = nil) {
        self.caseDescription = caseDescription
        // See HomeViewModel's init comment on why this isn't a default parameter value.
        historyStore = CaseHistoryStore(service: service ?? ScrubPrepServiceFactory.make())
    }

    var hasChanges: Bool { draft != savedNotes }

    func load() async {
        loadState = .loading
        do {
            guard let found = try await historyStore.find(caseDescription: caseDescription) else {
                loadState = .notSaved
                return
            }
            scrubCase = found
            savedNotes = found.notes ?? ""
            draft = savedNotes
            loadState = .loaded
        } catch {
            loadState = .failed
        }
    }

    /// Returns the updated case, or `nil` if the save failed — the sheet only dismisses
    /// on success.
    func save() async -> ScrubCase? {
        guard let scrubCase else { return nil }
        isSaving = true
        defer { isSaving = false }
        do {
            let updated = try await historyStore.saveNotes(draft, for: scrubCase)
            self.scrubCase = updated
            savedNotes = updated.notes ?? ""
            return updated
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Scrub Prep wasn't able to save your notes. Please try again."
            return nil
        }
    }
}
