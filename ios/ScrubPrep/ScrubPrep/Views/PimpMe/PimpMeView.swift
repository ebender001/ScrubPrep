import SwiftUI

/// The interactive Pimp Me experience: pick a difficulty, then answer one question at a
/// time with feedback after each, ending in a readiness summary (spec §7-8). Each
/// difficulty can only be completed once per case — completed ones are locked and shown
/// with a checkmark; tapping one reviews its saved transcript instead of restarting.
struct PimpMeView: View {
    @State private var viewModel: PimpMeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingError = false

    init(caseDescription: String, prep: ORPrep) {
        _viewModel = State(wrappedValue: PimpMeViewModel(caseDescription: caseDescription, prep: prep))
    }

    var body: some View {
        content
            .navigationTitle("Quiz Me")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Couldn't continue", isPresented: $isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                isShowingError = newValue != nil
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .pickingDifficulty:
            if viewModel.isLoadingCompletedDifficulties {
                LoadingView(title: "Loading your progress\u{2026}", messages: [])
            } else {
                PimpMeDifficultyPicker(
                    prepTitle: viewModel.prep.title,
                    completedDifficulties: viewModel.completedDifficulties,
                    selectedDifficulty: viewModel.difficulty,
                    allDifficultiesCompleted: allDifficultiesCompleted,
                    onSelectDifficulty: viewModel.selectDifficulty,
                    onStart: viewModel.start
                )
            }
        case .starting:
            LoadingView(
                title: "Starting your session\u{2026}",
                messages: ["Reviewing your prep", "Preparing the first question"]
            )
        case .answering, .reviewingFeedback:
            PimpMeSessionView(viewModel: viewModel)
        case .completed(let summary):
            PimpMeSummaryView(
                summary: summary,
                prepTitle: viewModel.prep.title,
                allDifficultiesCompleted: allDifficultiesCompleted,
                onChooseAnotherDifficulty: viewModel.backToDifficultyPicker,
                onDone: { dismiss() }
            )
        case .reviewingTranscript(let level, let transcript, let summary):
            PimpMeTranscriptView(
                difficulty: level,
                transcript: transcript,
                summary: summary,
                prepTitle: viewModel.prep.title,
                onBack: viewModel.backToDifficultyPicker
            )
        }
    }

    private var allDifficultiesCompleted: Bool {
        viewModel.completedDifficulties.count == PimpDifficulty.allCases.count
    }
}

#Preview {
    NavigationStack {
        PimpMeView(caseDescription: "Lap chole for acute cholecystitis", prep: .mockLapChole)
    }
}
