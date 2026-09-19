import SwiftUI

/// The Rapid Fire flow (spec §9): exactly 5 high-yield question/answer pairs, one at a
/// time — tap to reveal the answer, then advance. No grading, no lengthy explanations,
/// just a fast self-test in the last two minutes before scrubbing in.
struct RapidFireView: View {
    @State private var viewModel: RapidFireViewModel
    @Environment(\.dismiss) private var dismiss

    init(caseDescription: String, prep: ORPrep) {
        _viewModel = State(wrappedValue: RapidFireViewModel(caseDescription: caseDescription, prep: prep))
    }

    var body: some View {
        content
            .navigationTitle("Rapid Fire")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            LoadingView(
                title: "Preparing your rapid fire\u{2026}",
                messages: ["Pulling the highest-yield questions", "Keeping it to five", "No lengthy explanations"]
            )
        } else if let qa = viewModel.currentQuestion {
            RapidFireCardView(
                qa: qa,
                currentIndex: viewModel.currentIndex,
                totalCount: viewModel.questions.count,
                isAnswerRevealed: viewModel.isAnswerRevealed,
                isLastQuestion: viewModel.isLastQuestion,
                onReveal: viewModel.revealAnswer,
                onAdvance: viewModel.advance
            )
        } else if viewModel.isComplete {
            RapidFireCompletedView(
                questionCount: viewModel.questions.count,
                caseTitle: viewModel.prep.title,
                canGoAgain: viewModel.canGoAgain,
                onGoAgain: viewModel.restart,
                onDone: { dismiss() }
            )
        } else {
            RapidFireFailedView(errorMessage: viewModel.errorMessage, onRetry: viewModel.load)
        }
    }
}

#Preview {
    NavigationStack {
        RapidFireView(caseDescription: "Lap chole for acute cholecystitis", prep: .mockLapChole)
    }
}
