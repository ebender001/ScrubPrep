import Combine
import Foundation
import SwiftUI

/// Local persistence for completed OR Preps (spec §11 — case history is client-side
/// for v1). Backed by a JSON file in the app's Documents directory.
/// No explicit `@MainActor` needed — the project's default actor isolation is MainActor.
final class CaseHistoryStore: ObservableObject {
    @Published private(set) var cases: [ScrubCase] = []

    private let fileURL: URL

    init(fileName: String = "case_history.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documents.appendingPathComponent(fileName)
        load()
    }

    func add(_ scrubCase: ScrubCase) {
        cases.insert(scrubCase, at: 0)
        save()
    }

    func markReviewed(_ scrubCase: ScrubCase) {
        guard let index = cases.firstIndex(where: { $0.id == scrubCase.id }) else { return }
        cases[index].lastReviewedAt = Date()
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        cases = (try? decoder.decode([ScrubCase].self, from: data)) ?? []
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(cases) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
