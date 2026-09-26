import SwiftUI

/// The My Notes sheet for a case, opened from the prep screen's My Notes button or its
/// toolbar icon. Edits a draft; nothing is saved until Save is tapped.
struct CaseNotesSheet: View {
    let caseTitle: String
    /// Called with the updated case after a successful save.
    var onSaved: ((ScrubCase) -> Void)?

    @State private var viewModel: CaseNotesViewModel
    @State private var isShowingError = false
    @FocusState private var isEditorFocused: Bool
    @Environment(\.dismiss) private var dismiss

    init(
        caseDescription: String,
        caseTitle: String,
        viewModel: CaseNotesViewModel? = nil,
        onSaved: ((ScrubCase) -> Void)? = nil
    ) {
        self.caseTitle = caseTitle
        self.onSaved = onSaved
        _viewModel = State(initialValue: viewModel ?? CaseNotesViewModel(caseDescription: caseDescription))
    }

    var body: some View {
        NavigationStack {
            content
                .background(Color(.systemGroupedBackground))
                .navigationTitle("My Notes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .cancel) { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Button("Save") {
                                Task {
                                    if let updated = await viewModel.save() {
                                        onSaved?(updated)
                                        dismiss()
                                    }
                                }
                            }
                            .disabled(viewModel.loadState != .loaded || !viewModel.hasChanges)
                        }
                    }
                }
        }
        // Swiping down would silently discard unsaved edits.
        .interactiveDismissDisabled(viewModel.hasChanges)
        .task { await viewModel.load() }
        .alert("Couldn't save your notes", isPresented: $isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: viewModel.errorMessage) { _, newValue in
            isShowingError = newValue != nil
        }
        .onChange(of: isShowingError) { _, isShowing in
            if !isShowing { viewModel.errorMessage = nil }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .notSaved:
            ContentUnavailableView(
                "Case not saved",
                systemImage: "note.text",
                description: Text("Notes can be added once this case is saved to your Cases.")
            )
        case .failed:
            ContentUnavailableView {
                Label("Couldn't load your notes", systemImage: "exclamationmark.triangle")
            } actions: {
                Button("Try Again") { Task { await viewModel.load() } }
            }
        case .loaded:
            editor
        }
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(caseTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            TextEditor(text: $viewModel.draft)
                .focused($isEditorFocused)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
                .overlay(alignment: .topLeading) {
                    if viewModel.draft.isEmpty {
                        Text("Pearls, attending preferences, things to look up\u{2026}")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }

            // Routine privacy guidance, not an error — no warning color.
            Label {
                Text("No patient-identifying information")
            } icon: {
                Image(systemName: "lock.shield")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .onAppear { isEditorFocused = true }
    }
}

#if DEBUG
#Preview {
    let prep = ORPrep.mockLapChole
    let service = MockScrubPrepService(cases: [
        ScrubCase(
            id: "case1",
            caseDescription: prep.title,
            prep: prep,
            notes: "Dr. K wants the critical view called out before clipping.",
            createdAt: Date(),
            updatedAt: Date(),
            lastReviewedAt: nil
        ),
    ])
    Text("Prep")
        .sheet(isPresented: .constant(true)) {
            CaseNotesSheet(
                caseDescription: prep.title,
                caseTitle: prep.title,
                viewModel: CaseNotesViewModel(caseDescription: prep.title, service: service)
            )
        }
}
#endif
