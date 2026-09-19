import SwiftUI

/// The "Likely questions" card at the bottom of an OR Prep — omitted entirely when the
/// prep has none.
struct PrepLikelyQuestionsCard: View {
    let questions: [QAPair]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Likely questions", systemImage: "bubble.left.and.bubble.right")
                .font(.headline)
            ForEach(questions) { qa in
                VStack(alignment: .leading, spacing: 3) {
                    Text(qa.question)
                        .font(.subheadline.weight(.medium))
                    Text(qa.answer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
    }
}

#Preview {
    PrepLikelyQuestionsCard(questions: [
        QAPair(
            question: "What structures define the hepatocystic triangle?",
            answer: "Cystic duct, common hepatic duct, and the inferior liver edge."
        ),
    ])
    .padding()
}
