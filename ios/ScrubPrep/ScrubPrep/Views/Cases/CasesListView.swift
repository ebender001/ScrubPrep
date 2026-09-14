import SwiftUI

/// Full case history list (spec §11) — the Home screen only shows the 5 most recent.
struct CasesListView: View {
    @ObservedObject var historyStore: CaseHistoryStore

    var body: some View {
        NavigationStack {
            Group {
                if historyStore.cases.isEmpty {
                    ContentUnavailableView(
                        "No cases yet",
                        systemImage: "clipboard",
                        description: Text("Cases you prepare will show up here.")
                    )
                } else {
                    List {
                        ForEach(historyStore.cases) { scrubCase in
                            NavigationLink {
                                PrepView(caseDescription: scrubCase.caseDescription, prep: scrubCase.prep)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(scrubCase.prep.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text(scrubCase.caseDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                historyStore.markReviewed(scrubCase)
                            })
                        }
                    }
                }
            }
            .navigationTitle("Cases")
        }
    }
}

#Preview {
    CasesListView(historyStore: CaseHistoryStore())
}
