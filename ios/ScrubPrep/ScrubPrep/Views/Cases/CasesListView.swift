import SwiftData
import SwiftUI

/// Full case history list (spec §11) — the Home screen only shows the 5 most recent.
struct CasesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\ScrubCase.createdAt, order: .reverse)]) private var cases: [ScrubCase]

    private var historyStore: CaseHistoryStore { CaseHistoryStore(modelContext: modelContext) }

    var body: some View {
        NavigationStack {
            Group {
                if cases.isEmpty {
                    ContentUnavailableView(
                        "No cases yet",
                        systemImage: "clipboard",
                        description: Text("Cases you prepare will show up here.")
                    )
                } else {
                    List {
                        ForEach(cases) { scrubCase in
                            NavigationLink(value: scrubCase) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(scrubCase.prep.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text(scrubCase.caseDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                // Ensures the whole row (not just the text's own tight
                                // bounding box) is tappable, all the way to the chevron.
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                        }
                        .onDelete { offsets in
                            historyStore.delete(at: offsets, in: cases)
                        }
                    }
                }
            }
            .navigationTitle("Cases")
            .navigationDestination(for: ScrubCase.self) { scrubCase in
                PrepView(caseDescription: scrubCase.caseDescription, prep: scrubCase.prep)
                    .onAppear { historyStore.markReviewed(scrubCase) }
            }
            .toolbar {
                if !cases.isEmpty {
                    EditButton()
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: ScrubCase.self, configurations: .init(isStoredInMemoryOnly: true))
    CasesListView()
        .modelContainer(container)
}
