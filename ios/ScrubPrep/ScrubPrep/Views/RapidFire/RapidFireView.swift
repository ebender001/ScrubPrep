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
            cardView(qa)
        } else if viewModel.isComplete {
            completedView
        } else {
            failedView
        }
    }

    private func cardView(_ qa: QAPair) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                progressHeader

                VStack(alignment: .leading, spacing: 12) {
                    Label("Question \(viewModel.currentIndex + 1)", systemImage: "bolt.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.yellow)
                    Text(qa.question)
                        .font(.title3.weight(.medium))

                    if viewModel.isAnswerRevealed {
                        Divider()
                        Text(qa.answer)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .transition(.opacity)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: .rect(cornerRadius: 16))
                .animation(.easeInOut(duration: 0.2), value: viewModel.isAnswerRevealed)

                if viewModel.isAnswerRevealed {
                    Button {
                        viewModel.advance()
                    } label: {
                        Text(viewModel.isLastQuestion ? "Finish" : "Next Question")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        viewModel.revealAnswer()
                    } label: {
                        Text("Reveal Answer")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: Double(viewModel.currentIndex), total: Double(max(viewModel.questions.count, 1)))
                .tint(.yellow)
            Text("Question \(viewModel.currentIndex + 1) of \(viewModel.questions.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var completedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)
            Text("Ready to scrub.")
                .font(.title3.weight(.semibold))
            Text("You reviewed \(viewModel.questions.count) high-yield questions for \(viewModel.prep.title).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if !viewModel.canGoAgain {
                Text("That's the full \(RapidFireViewModel.maxTotalQuestions)-question review for this case.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                if viewModel.canGoAgain {
                    Button {
                        viewModel.restart()
                    } label: {
                        Text("Go Again")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                }

                if viewModel.canGoAgain {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var failedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text("Couldn't generate this review")
                .font(.headline)
            Text(viewModel.errorMessage ?? "Please try again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                viewModel.load()
            } label: {
                Text("Try Again")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        RapidFireView(caseDescription: "Lap chole for acute cholecystitis", prep: .mockLapChole)
    }
}
