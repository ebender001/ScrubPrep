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
    // The (trimmed) case description `generatedPrep` was actually prepared for — Home's
    // Pimp Me/Rapid Fire buttons are only enabled once this matches the current
    // `caseDescription` (see isCurrentCasePrepared), so those features are never
    // reachable from Home until Prepare Me has been tapped for that exact case. Editing
    // the text afterward re-locks them until Prepare Me is tapped again.
    @Published private(set) var preparedCaseDescription: String?
    // Set when Pimp Me is started directly from Home, using the prep already generated
    // by Prepare Me (see isCurrentCasePrepared) — this flag drives navigation straight
    // into the interactive session instead of PrepView.
    @Published var pimpMePrep: ORPrep?
    @Published var navigateToPimpMe = false
    // Same idea as pimpMePrep/navigateToPimpMe, for Rapid Fire started directly from Home.
    @Published var rapidFirePrep: ORPrep?
    @Published var navigateToRapidFire = false

    // Backend-authoritative — not cached locally. Loaded via loadCases(), called from
    // HomeView's .task and refreshed after anything that mutates a case.
    @Published private(set) var recentCases: [ScrubCase] = []

    // No specialty is selected on first launch — the case-entry card shows no quick-pick
    // chips until the user picks one from the specialty row (spec: specialty selection is
    // the first step, not a default). Kept as full CaseType values (not just names) so the
    // chip can show the short name while inserting fullName into the text field on tap.
    @Published var exampleChips: [CaseType] = []

    // Shown instantly from SpecialtyCache on launch, then silently refreshed from the
    // network — see backend/cloud/scrubPrep/specialties.js.
    @Published var specialties: [Specialty]
    // Restored from SelectedSpecialtyStore on launch so closing and reopening the app
    // remembers the student's specialty instead of resetting to "no specialty".
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
    init(service: ScrubPrepServicing? = nil) {
        let resolvedService = service ?? ScrubPrepServiceFactory.make()
        self.service = resolvedService
        self.historyStore = CaseHistoryStore(service: resolvedService)

        let cachedSpecialties = SpecialtyCache.load()
        self.specialties = cachedSpecialties
        if let persistedID = SelectedSpecialtyStore.load() {
            self.selectedSpecialty = cachedSpecialties.first { $0.id == persistedID }
        }

        loadCaseTypes()
        refreshSpecialties()
    }

    /// Fetches the signed-in user's saved cases from the backend. Failure is silent —
    /// same "never let a decorative fetch block or error out the primary flow" reasoning
    /// as loadCaseTypes/refreshSpecialties; Recent Cases just stays empty/stale.
    func loadCases() async {
        if let cases = try? await historyStore.listAll() {
            recentCases = cases
        }
    }

    /// Tapping "Review" on a Recent Cases row.
    func reviewRecentCase(_ scrubCase: ScrubCase) async {
        try? await historyStore.markReviewed(scrubCase)
        generatedPrep = scrubCase.prep
        caseDescription = scrubCase.caseDescription
        preparedCaseDescription = scrubCase.caseDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        navigateToPrep = true
        await loadCases()
    }

    /// Tapping "Pimp Me" on a Recent Cases row.
    func startPimpMeFromRecentCase(_ scrubCase: ScrubCase) async {
        try? await historyStore.markReviewed(scrubCase)
        caseDescription = scrubCase.caseDescription
        generatedPrep = scrubCase.prep
        preparedCaseDescription = scrubCase.caseDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        pimpMePrep = scrubCase.prep
        navigateToPimpMe = true
        await loadCases()
    }

    /// Tapping "Rapid Fire" on a Recent Cases row.
    func startRapidFireFromRecentCase(_ scrubCase: ScrubCase) async {
        try? await historyStore.markReviewed(scrubCase)
        caseDescription = scrubCase.caseDescription
        generatedPrep = scrubCase.prep
        preparedCaseDescription = scrubCase.caseDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        rapidFirePrep = scrubCase.prep
        navigateToRapidFire = true
        await loadCases()
    }

    /// True once `generatedPrep` was actually prepared for the case description currently
    /// in the text field — drives whether Home's Pimp Me/Rapid Fire buttons are enabled.
    /// Editing the text after preparing flips this back to false until Prepare Me is
    /// tapped again, so those buttons can never trigger AI generation on their own.
    var isCurrentCasePrepared: Bool {
        guard let preparedCaseDescription else { return false }
        return preparedCaseDescription == caseDescription.trimmingCharacters(in: .whitespacesAndNewlines)
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
    /// UI without the user needing to reinstall or manually refresh. Always overwrites
    /// (rather than checking for a change first) — Specialty's Equatable conformance is
    /// identity-based (id only, see Models/CaseType.swift), so a stale cache with the same
    /// ids but different content (e.g. a newly added field) would otherwise compare equal
    /// and never get refreshed.
    ///
    /// Also (re)resolves the persisted/current selection against the fresh list: this
    /// re-syncs content (e.g. a corrected exampleCaseDescription) for an already-selected
    /// specialty, and restores the persisted selection on a launch where the specialty
    /// cache was empty (so it couldn't be resolved synchronously in init).
    private func refreshSpecialties() {
        Task {
            guard let fetched = try? await service.listSpecialties(), !fetched.isEmpty else { return }
            specialties = fetched
            SpecialtyCache.save(fetched)

            if let targetID = selectedSpecialty?.id ?? SelectedSpecialtyStore.load() {
                selectedSpecialty = fetched.first { $0.id == targetID }
                if let selectedSpecialty, !allCaseTypes.isEmpty {
                    exampleChips = matchingChips(for: selectedSpecialty)
                }
            }
        }
    }

    /// Tapping the already-selected specialty clears back to the no-selection state (no
    /// quick-pick chips) rather than falling back to some default specialty. Either way,
    /// the case description is cleared — a case typed/tapped in under one specialty
    /// shouldn't linger after switching to another. The selection is persisted so it's
    /// remembered the next time the app launches.
    func selectSpecialty(_ specialty: Specialty) {
        caseDescription = ""
        if selectedSpecialty == specialty {
            selectedSpecialty = nil
            exampleChips = []
            SelectedSpecialtyStore.save(nil)
            return
        }
        selectedSpecialty = specialty
        exampleChips = matchingChips(for: specialty)
        SelectedSpecialtyStore.save(specialty.id)
    }

    private func matchingChips(for specialty: Specialty) -> [CaseType] {
        allCaseTypes.filter { $0.specialty == specialty }
    }

    func prepareCase() {
        resolvePrep { [weak self] prep in
            self?.generatedPrep = prep
            self?.navigateToPrep = true
        }
    }

    /// Pimp Me tapped directly from Home — only reachable once `isCurrentCasePrepared` is
    /// true (see HomeView's `.disabled`), so this always has an already-generated prep on
    /// hand and never triggers its own AI call.
    func startPimpMe() {
        guard isCurrentCasePrepared, let prep = generatedPrep else { return }
        pimpMePrep = prep
        navigateToPimpMe = true
    }

    /// Rapid Fire tapped directly from Home — same precondition as `startPimpMe()`.
    func startRapidFire() {
        guard isCurrentCasePrepared, let prep = generatedPrep else { return }
        rapidFirePrep = prep
        navigateToRapidFire = true
    }

    /// Resolves an `ORPrep` for the current `caseDescription` — reusing a cached one from
    /// history if this exact case was already prepared, otherwise generating a new one —
    /// then hands it to `onReady`. Only called from `prepareCase()`: Pimp Me/Rapid Fire
    /// from Home reuse that result instead of resolving their own (see
    /// `isCurrentCasePrepared`), so Prepare Me is the only thing on Home that can trigger
    /// AI generation.
    private func resolvePrep(onReady: @escaping (ORPrep) -> Void) {
        let trimmed = caseDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        errorMessage = nil
        isGenerating = true

        let requestID = UUID()
        currentRequestID = requestID

        generationTask = Task {
            do {
                // Already prepared this case? Reuse it — no network/OpenAI hit. Source of
                // truth is the backend (not a local cache), so this is itself a network
                // call, just a much cheaper one than actually generating a prep.
                if let existing = try await historyStore.find(caseDescription: trimmed) {
                    guard !Task.isCancelled, requestID == currentRequestID else { return }
                    try? await historyStore.markReviewed(existing)
                    isGenerating = false
                    preparedCaseDescription = trimmed
                    onReady(existing.prep)
                    return
                }

                let prep = try await service.generatePrep(caseDescription: trimmed)
                guard !Task.isCancelled, requestID == currentRequestID else { return }
                _ = try? await historyStore.addOrUpdate(caseDescription: trimmed, prep: prep)
                isGenerating = false
                preparedCaseDescription = trimmed
                onReady(prep)
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
