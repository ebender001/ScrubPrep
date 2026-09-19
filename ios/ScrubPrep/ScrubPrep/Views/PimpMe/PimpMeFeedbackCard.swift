import SwiftUI

/// Feedback shown after submitting an answer in a Pimp Me session — assessment, the
/// question/answer just submitted, and the teaching point.
struct PimpMeFeedbackCard: View {
    let turn: PimpTurn

    var body: some View {
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
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
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
    PimpMeFeedbackCard(
        turn: PimpTurn(
            question: "What structures define the hepatocystic triangle?",
            answer: "Cystic duct, common hepatic duct, and the liver edge.",
            assessment: .correct,
            feedback: "Good — you're on the right track. Here's a quick refinement.",
            teachingPoint: "Remember to name the specific structures at risk, not just the general area."
        )
    )
    .padding()
}
