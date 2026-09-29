import SwiftUI

/// The "Sources" card at the bottom of each Learn reference screen — its citations as
/// tappable links, plus the review statement.
struct LearnSourcesCard: View {
    let sources: [LearnSource]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sources and further reading", systemImage: "books.vertical")
                .font(.headline)

            ForEach(sources) { source in
                LearnSourceRow(source: source)
            }

            Text(LearnSources.reviewStatement)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
    }
}

#Preview {
    ScrollView {
        LearnSourcesCard(sources: LearnSources.positioning)
            .padding()
    }
}
