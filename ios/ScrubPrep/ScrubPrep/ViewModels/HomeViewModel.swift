import Combine
import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var caseDescription: String = ""
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var generatedPrep: ORPrep?
    @Published var navigateToPrep = false

    // No specialty is selected on first launch — the case-entry card shows no quick-pick
    // chips until the user picks one from the specialty row (spec: specialty selection is
    // the first step, not a default). Kept as full CaseType values (not just names) so the
    // chip can show the short name while inserting fullName into the text field on tap.
    @Published var exampleChips: [CaseType] = []

    // Shown instantly from SpecialtyCache on launch, then silently refreshed from the
    // network — see backend/cloud/scrubPrep/specialties.js.
    @Published var specialties: [Specialty] = SpecialtyCache.load()
    @Published var selectedSpecialty: Specialty?

    private var allCaseTypes: [CaseType] = []

    let loadingMessages = [
        "Reviewing the operation",
        "Identifying key anatomy",
        "Finding likely questions",
        "Building your prep",
    ]

    private let service: ScrubPrepServicing
    private let historyStore: CaseHistoryStore
    private var generationTask: Task<Void, Never>?

    // Guards against acting on a response that arrives after the user cancelled (or
    // after a newer request superseded it). ParseSwift's public API doesn't expose a
    // cancellable handle for the underlying network request (see ParseScrubPrepService),
    // so Task.cancel() alone can't abort the in-flight HTTP call — but this ensures the
    // app ignores its result entirely rather than surprising the user with a late
    // navigation or stale data.
    private var currentRequestID: UUID?

    // `service` isn't defaulted in the parameter list on purpose: ScrubPrepServiceFactory.make()
    // is MainActor-isolated, and default-argument expressions evaluate in a nonisolated
    // context under this project's concurrency settings. Resolving it in the body instead
    // (same-actor call, since HomeViewModel is @MainActor) avoids that warning.
    init(service: ScrubPrepServicing? = nil, historyStore: CaseHistoryStore) {
        self.service = service ?? ScrubPrepServiceFactory.make()
        self.historyStore = historyStore
        loadCaseTypes()
        refreshSpecialties()
    }

    /// Fetches the full case type catalog used to filter quick-picks once a specialty is
    /// selected. Failure is silent — the specialty row still works for browsing, it just
    /// won't be able to show matching quick-picks (spec: never let a decorative fetch
    /// block or error out the primary "prepare a case" flow).
    private func loadCaseTypes() {
        Task {
            guard let caseTypes = try? await service.listCaseTypes() else { return }
            allCaseTypes = caseTypes
            if let selected = selectedSpecialty {
                exampleChips = matchingChips(for: selected)
            }
        }
    }

    /// Shows the cached specialty list instantly (if any), then always refreshes from the
    /// network in the background so a backend-side catalog change eventually reaches the
    /// UI without the user needing to reinstall or manually refresh.
    private func refreshSpecialties() {
        Task {
            guard let fetched = try? await service.listSpecialties(), !fetched.isEmpty else { return }
            if fetched != specialties {
                specialties = fetched
                SpecialtyCache.save(fetched)
            }
        }
    }

    /// Tapping the already-selected specialty clears back to the no-selection state (no
    /// quick-pick chips) rather than falling back to some default specialty.
    func selectSpecialty(_ specialty: Specialty) {
        if selectedSpecialty == specialty {
            selectedSpecialty = nil
            exampleChips = []
            return
        }
        selectedSpecialty = specialty
        exampleChips = matchingChips(for: specialty)
    }

    private func matchingChips(for specialty: Specialty) -> [CaseType] {
        allCaseTypes.filter { $0.specialty == specialty }
    }

    func prepareCase() {
        let trimmed = caseDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        errorMessage = nil

        // Already prepared this case on this device? Reuse it — no network/OpenAI hit.
        // Source of truth is SwiftData (persists across launches), not an in-memory
        // cache, so this works even the first time a case is re-entered after relaunch.
        if let existing = historyStore.find(caseDescription: trimmed) {
            historyStore.markReviewed(existing)
            generatedPrep = existing.prep
            navigateToPrep = true
            return
        }

        isGenerating = true

        let requestID = UUID()
        currentRequestID = requestID

        generationTask = Task {
            do {
                let prep = try await service.generatePrep(caseDescription: trimmed)
                guard !Task.isCancelled, requestID == currentRequestID else { return }
                historyStore.addOrUpdate(caseDescription: trimmed, prep: prep)
                generatedPrep = prep
                isGenerating = false
                navigateToPrep = true
            } catch {
                guard !Task.isCancelled, requestID == currentRequestID else { return }
                isGenerating = false
                errorMessage = (error as? LocalizedError)?.errorDescription
                    ?? "Scrub Prep wasn't able to generate your preparation session. Please try again."
            }
        }
    }

    /// Bails out of an in-progress generation (spec: Cancel on the preparing screen
    /// returns to an interactive Home screen immediately).
    func cancelPreparing() {
        generationTask?.cancel()
        generationTask = nil
        currentRequestID = nil
        isGenerating = false
    }
}
