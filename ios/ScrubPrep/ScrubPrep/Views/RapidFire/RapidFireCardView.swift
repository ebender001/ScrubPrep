import SwiftUI

/// The per-question card in the Rapid Fire flow — question, then (once revealed) the
/// answer, then a button to advance.
struct RapidFireCardView: View {
    let qa: QAPair
    let currentIndex: Int
    let totalCount: Int
    let isAnswerRevealed: Bool
    let isLastQuestion: Bool
    let onReveal: () -> Void
    let onAdvance: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RapidFireProgressHeader(currentIndex: currentIndex, totalCount: totalCount)

                VStack(alignment: .leading, spacing: 12) {
                    Label("Question \(currentIndex + 1)", systemImage: "bolt.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.yellow)
                    Text(qa.question)
                        .font(.title3.weight(.medium))

                    if isAnswerRevealed {
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
                .animation(.easeInOut(duration: 0.2), value: isAnswerRevealed)

                if isAnswerRevealed {
                    Button(action: onAdvance) {
                        Text(isLastQuestion ? "Finish" : "Next Question")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: onReveal) {
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
}

#Preview {
    RapidFireCardView(
        qa: QAPair(question: "What structures define Calot's triangle?", answer: "Cystic duct, common hepatic duct, and the liver edge."),
        currentIndex: 0,
        totalCount: 5,
        isAnswerRevealed: false,
        isLastQuestion: false,
        onReveal: {},
        onAdvance: {}
    )
}
