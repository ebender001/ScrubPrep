import SwiftUI

/// Full case history list (spec §11) — the Home screen only shows the 5 most recent.
struct CasesListView: View {
    @State private var viewModel: CasesListViewModel
    @State private var isShowingError = false
    @AppStorage("casesSortOrder.v1") private var sortOrder: CaseSortOrder = .newestFirst

    /// `viewModel` is injectable for previews; `nil` builds the default one here, since a
    /// default argument value can't call the MainActor-isolated initializer.
    init(viewModel: CasesListViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? CasesListViewModel())
    }

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
                    casesList
                }
            }
            .navigationTitle("Cases")
            .navigationDestination(for: ScrubCase.self) { scrubCase in
                PrepView(caseDescription: scrubCase.caseDescription, prep: scrubCase.prep)
                    .task { await viewModel.markReviewed(scrubCase) }
            }
            .toolbar {
                if !viewModel.cases.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        sortFilterMenu
                    }
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

    private var casesList: some View {
        let visibleCases = viewModel.visibleCases(sortedBy: sortOrder)
        return List {
            ForEach(visibleCases) { scrubCase in
                NavigationLink(value: scrubCase) {
                    CaseRow(scrubCase: scrubCase)
                }
            }
            // Offsets index into the filtered/sorted rows, not `viewModel.cases`, so map
            // them back to the cases themselves before deleting.
            .onDelete { offsets in
                viewModel.delete(offsets.map { visibleCases[$0] })
            }
        }
        .overlay {
            if visibleCases.isEmpty {
                if !viewModel.trimmedSearchText.isEmpty {
                    ContentUnavailableView.search(text: viewModel.trimmedSearchText)
                } else {
                    ContentUnavailableView {
                        Label("No matching cases", systemImage: "line.3.horizontal.decrease.circle")
                    } description: {
                        Text("No cases match the selected filters.")
                    } actions: {
                        Button("Clear filters", action: viewModel.clearFilters)
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search cases")
        .refreshable {
            await viewModel.load()
        }
    }

    private var sortFilterMenu: some View {
        // Toggles directly inside titled Sections rather than inline Pickers — an inline
        // Picker in a Menu becomes its own untitled section, which hides these headers.
        Menu {
            Section("Sort by") {
                ForEach(CaseSortOrder.allCases) { order in
                    Toggle(order.title, isOn: selectionBinding(for: order, in: $sortOrder))
                }
            }

            if !viewModel.availableSpecialties.isEmpty {
                Section("Specialty") {
                    Toggle("All", isOn: selectionBinding(for: nil, in: $viewModel.specialtyFilter))
                    ForEach(viewModel.availableSpecialties) { specialty in
                        Toggle(specialty.name, isOn: selectionBinding(for: specialty.id, in: $viewModel.specialtyFilter))
                    }
                }
            }
        } label: {
            Image(systemName: viewModel.isFiltering
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Sort and filter")
    }

    /// Single-choice binding for a menu Toggle: on when `selection` equals `value`, and
    /// turning it on selects `value`. Turning the checked item off is ignored, so one
    /// option always stays selected, as with a Picker.
    private func selectionBinding<Value: Equatable>(for value: Value, in selection: Binding<Value>) -> Binding<Bool> {
        Binding(
            get: { selection.wrappedValue == value },
            set: { isOn in
                if isOn { selection.wrappedValue = value }
            }
        )
    }
}

/// One Cases list row: prep title, then the created date and specialty chip.
private struct CaseRow: View {
    let scrubCase: ScrubCase

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(scrubCase.prep.title)
                .font(.subheadline.weight(.semibold))
            HStack(spacing: 8) {
                Text(scrubCase.createdAt, format: .dateTime.month(.abbreviated).day().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let specialty = scrubCase.specialty {
                    Text(specialty.name)
                        .font(.caption2.weight(.medium))
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                }
            }
        }
        // Ensures the whole row (not just the text's own tight bounding box) is
        // tappable, all the way to the chevron.
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

#if DEBUG
private extension CasesListViewModel {
    /// Backed by a seeded MockScrubPrepService so previews don't hit the network.
    static func preview(searchText: String = "") -> CasesListViewModel {
        let generalSurgery = Specialty(id: "sp1", name: "General Surgery")
        let now = Date()
        let entries: [(prep: ORPrep, specialty: Specialty?, daysAgo: Double)] = [
            (.mockLapChole, generalSurgery, 0),
            (.mockAppendectomy, generalSurgery, 1),
            (.mockRightColectomy, nil, 2),
        ]
        let samples = entries.enumerated().map { index, entry in
            let date = now.addingTimeInterval(-entry.daysAgo * 86_400)
            return ScrubCase(
                id: "case\(index)",
                caseDescription: entry.prep.title,
                prep: entry.prep,
                specialty: entry.specialty,
                createdAt: date,
                updatedAt: date,
                lastReviewedAt: nil
            )
        }
        let viewModel = CasesListViewModel(service: MockScrubPrepService(cases: samples))
        viewModel.searchText = searchText
        return viewModel
    }
}

#Preview("Cases") {
    CasesListView(viewModel: .preview())
}

#Preview("No search results") {
    CasesListView(viewModel: .preview(searchText: "Craniotomy"))
}
#endif
