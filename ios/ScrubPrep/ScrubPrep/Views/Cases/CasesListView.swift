import SwiftUI

/// Full case history list (spec §11) — the Home screen only shows the 5 most recent.
struct CasesListView: View {
    @StateObject private var viewModel = CasesListViewModel()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

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
                                    Text(Self.dateFormatter.string(from: scrubCase.createdAt))
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
            .alert("Couldn't load your cases", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

#Preview {
    CasesListView()
}
