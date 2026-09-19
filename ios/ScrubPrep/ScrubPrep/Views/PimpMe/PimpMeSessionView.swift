import SwiftUI

/// The active question/answer/feedback loop of a Pimp Me session. Owns the answer
/// field's focus locally, since re-focusing after "Next Question" is entirely this
/// view's own concern.
struct PimpMeSessionView: View {
    @Bindable var viewModel: PimpMeViewModel
    @FocusState private var isAnswerFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let progress = viewModel.progress {
                    PimpMeProgressHeader(progress: progress)
                }

                if viewModel.phase == .reviewingFeedback, let turn = viewModel.lastTurn {
                    PimpMeFeedbackCard(turn: turn)
                    Button {
                        if !viewModel.isFinalFeedback {
                            isAnswerFocused = true
                        }
                        viewModel.continueToNextQuestion()
                    } label: {
                        Text(viewModel.isFinalFeedback ? "See Summary" : "Next Question")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    PimpMeQuestionCard(question: viewModel.currentQuestion ?? "")
                    PimpMeAnswerInput(
                        answerText: $viewModel.answerText,
                        isSubmitting: viewModel.isSubmitting,
                        isFocused: $isAnswerFocused,
                        onSubmit: {
                            isAnswerFocused = false
                            viewModel.submitAnswer()
                        }
                    )
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    PimpMeSessionView(viewModel: PimpMeViewModel(caseDescription: "Lap chole", prep: .mockLapChole))
}
