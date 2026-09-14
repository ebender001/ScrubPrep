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

    // Seeded default so the UI has something to show before (or if) the server-side
    // catalog fetch below completes — see backend/cloud/scrubPrep/caseTypes.js.
    @Published var exampleChips = ["Lap Chole", "Appendectomy", "Inguinal Hernia", "Colectomy"]

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
    }

    /// Refreshes the Home screen quick-picks from the server-side catalog. Failure is
    /// silent — the hardcoded fallback chips above stay in place (spec: never let a
    /// decorative fetch block or error out the primary "prepare a case" flow).
    private func loadCaseTypes() {
        Task {
            guard let caseTypes = try? await service.listCaseTypes() else { return }
            let featured = caseTypes.filter(\.featured).map(\.name)
            if !featured.isEmpty {
                exampleChips = featured
            }
        }
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
