import SwiftUI

/// The interactive Pimp Me experience: pick a difficulty, then answer one question at a
/// time with feedback after each, ending in a readiness summary (spec §7-8).
struct PimpMeView: View {
    @StateObject private var viewModel: PimpMeViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isAnswerFocused: Bool

    init(caseDescription: String, prep: ORPrep) {
        _viewModel = StateObject(wrappedValue: PimpMeViewModel(caseDescription: caseDescription, prep: prep))
    }

    var body: some View {
        content
            .navigationTitle("Pimp Me")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Couldn't continue", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .pickingDifficulty:
            difficultyPicker
        case .starting:
            LoadingView(
                title: "Starting your session\u{2026}",
                messages: ["Reviewing your prep", "Preparing the first question"]
            )
        case .answering, .reviewingFeedback:
            sessionView
        case .completed(let summary):
            summaryView(summary)
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    // MARK: - Difficulty picker

    private var difficultyPicker: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Test me before I scrub.")
                    .font(.title3.weight(.semibold))
                Text("Interactive questions tailored to \(viewModel.prep.title). Pick how tough you want it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 10) {
                    ForEach(PimpDifficulty.allCases) { level in
                        difficultyRow(level)
                    }
                }

                Button {
                    viewModel.start()
                } label: {
                    Text("Start")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private func difficultyRow(_ level: PimpDifficulty) -> some View {
        let isSelected = viewModel.difficulty == level
        return Button {
            viewModel.difficulty = level
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.displayName)
                        .font(.subheadline.weight(.semibold))
                    Text(level.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
            .background(
                isSelected ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Session (question + feedback)

    private var sessionView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let progress = viewModel.progress {
                    progressHeader(progress)
                }

                if viewModel.phase == .reviewingFeedback, let turn = viewModel.lastTurn {
                    feedbackCard(for: turn)
                    Button {
                        isAnswerFocused = true
                        viewModel.continueToNextQuestion()
                    } label: {
                        Text("Next Question")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    questionCard
                    answerInput
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func progressHeader(_ progress: PimpProgress) -> some View {
        let questionNumber = min(progress.index + 1, progress.total)
        return VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: Double(progress.index), total: Double(max(progress.total, 1)))
                .tint(Color.accentColor)
            Text("Question \(questionNumber) of \(progress.total)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Question", systemImage: "flame.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
            Text(viewModel.currentQuestion ?? "")
                .font(.title3.weight(.medium))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var answerInput: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                if viewModel.answerText.isEmpty {
                    Text("Type your answer")
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                TextEditor(text: $viewModel.answerText)
                    .frame(minHeight: 90)
                    .focused($isAnswerFocused)
                    .scrollContentBackground(.hidden)
                    .disabled(viewModel.isSubmitting)
            }
            .padding(8)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button {
                isAnswerFocused = false
                viewModel.submitAnswer()
            } label: {
                if viewModel.isSubmitting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                } else {
                    Text("Submit")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSubmitting || viewModel.answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func feedbackCard(for turn: PimpTurn) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(turn.assessment.label, systemImage: turn.assessment.systemImage)
                .font(.headline)
                .foregroundStyle(turn.assessment.tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(turn.question)
                    .font(.subheadline.weight(.medium))
                Text("Your answer: \(turn.answer)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Feedback")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(turn.feedback)
                    .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Teaching Point")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(turn.teachingPoint)
                    .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Summary

    private func summaryView(_ summary: PimpSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Session Complete")
                        .font(.title3.weight(.semibold))
                    Text(viewModel.prep.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                SectionCard(title: "You're strong on", systemImage: "checkmark.seal.fill", items: summary.strong)
                SectionCard(title: "Review before you scrub", systemImage: "book.closed.fill", items: summary.review)
                SectionCard(title: "Two-minute review", systemImage: "clock.fill", items: summary.twoMinuteReview)

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
            .padding()
        }
    }
}

private extension PimpAssessment {
    var label: String {
        switch self {
        case .correct: return "Correct"
        case .partiallyCorrect: return "Partially Correct"
        case .incorrect: return "Incorrect"
        }
    }

    var systemImage: String {
        switch self {
        case .correct: return "checkmark.circle.fill"
        case .partiallyCorrect: return "exclamationmark.circle.fill"
        case .incorrect: return "xmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .correct: return .green
        case .partiallyCorrect: return .orange
        case .incorrect: return .red
        }
    }
}

#Preview {
    NavigationStack {
        PimpMeView(caseDescription: "Lap chole for acute cholecystitis", prep: .mockLapChole)
    }
}
