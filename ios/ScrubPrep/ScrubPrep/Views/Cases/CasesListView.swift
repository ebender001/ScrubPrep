import SwiftUI

/// Full case history list (spec §11) — the Home screen only shows the 5 most recent.
struct CasesListView: View {
    @State private var viewModel = CasesListViewModel()
    @State private var isShowingError = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.cases.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.cases.isEmpty {
                    ContentUnavailableView(
                        "No cases yet",
                        systemImage: "clipboard",
                        description: Text("Cases you prepare will show up here.")
                    )
                } else {
                    List {
                        ForEach(viewModel.cases) { scrubCase in
                            NavigationLink(value: scrubCase) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(scrubCase.prep.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text(scrubCase.createdAt, format: .dateTime.month(.abbreviated).day().year())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                // Ensures the whole row (not just the text's own tight
                                // bounding box) is tappable, all the way to the chevron.
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                        }
                        .onDelete { offsets in
                            viewModel.delete(at: offsets)
                        }
                    }
                    .refreshable {
                        await viewModel.load()
                    }
                }
            }
            .navigationTitle("Cases")
            .navigationDestination(for: ScrubCase.self) { scrubCase in
                PrepView(caseDescription: scrubCase.caseDescription, prep: scrubCase.prep)
                    .task { await viewModel.markReviewed(scrubCase) }
            }
            .toolbar {
                if !viewModel.cases.isEmpty {
                    EditButton()
                }
            }
            .task {
                await viewModel.load()
            }
            .alert("Couldn't load your cases", isPresented: $isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                isShowingError = newValue != nil
            }
        }
    }
}

#Preview {
    CasesListView()
}
