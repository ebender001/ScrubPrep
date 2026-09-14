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

    let exampleChips = ["Lap Chole", "Appendectomy", "Inguinal Hernia", "Colectomy"]

    let loadingMessages = [
        "Reviewing the operation",
        "Identifying key anatomy",
        "Finding likely questions",
        "Building your prep",
    ]

    private let service: ScrubPrepServicing
    private let historyStore: CaseHistoryStore

    // `service` isn't defaulted in the parameter list on purpose: ScrubPrepServiceFactory.make()
    // is MainActor-isolated, and default-argument expressions evaluate in a nonisolated
    // context under this project's concurrency settings. Resolving it in the body instead
    // (same-actor call, since HomeViewModel is @MainActor) avoids that warning.
    init(service: ScrubPrepServicing? = nil, historyStore: CaseHistoryStore) {
        self.service = service ?? ScrubPrepServiceFactory.make()
        self.historyStore = historyStore
    }

    func prepareCase() {
        let trimmed = caseDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        errorMessage = nil
        isGenerating = true

        Task {
            do {
                let prep = try await service.generatePrep(caseDescription: trimmed)
                historyStore.add(ScrubCase(caseDescription: trimmed, prep: prep))
                generatedPrep = prep
                isGenerating = false
                navigateToPrep = true
            } catch {
                isGenerating = false
                errorMessage = (error as? LocalizedError)?.errorDescription
                    ?? "Scrub Prep wasn't able to generate your preparation session. Please try again."
            }
        }
    }
}
