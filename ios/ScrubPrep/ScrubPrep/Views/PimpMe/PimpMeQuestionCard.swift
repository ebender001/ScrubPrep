import SwiftUI

/// The current question in a Pimp Me session.
struct PimpMeQuestionCard: View {
    let question: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Question", systemImage: "flame.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
            Text(question)
                .font(.title3.weight(.medium))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
    }
}

#Preview {
    PimpMeQuestionCard(question: "What structures define the hepatocystic triangle?")
        .padding()
}
