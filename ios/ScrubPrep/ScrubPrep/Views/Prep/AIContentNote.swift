import SwiftUI

/// Discloses that a screen's medical content is AI-generated and points to sources (App
/// Store guideline 1.4.1). On a prep screen, pass the operation's title and references:
/// verified references are listed, and without any the student gets a StatPearls search
/// for the operation instead. Must be shown inside a NavigationStack.
struct AIContentNote: View {
    var operationTitle: String?
    var references: [PrepReference]?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text("AI-generated for study. Verify with your clinical team and standard references.")
            } icon: {
                Image(systemName: "sparkles")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let references, !references.isEmpty {
                Text("References for this operation")
                    .font(.caption.weight(.semibold))
                    .padding(.top, 2)
                ForEach(references) { reference in
                    referenceLink(reference.title, detail: reference.source, url: reference.url)
                }
            } else if let operationTitle, let searchURL = Self.statPearlsSearchURL(for: operationTitle) {
                referenceLink("Look up \(operationTitle) in StatPearls", detail: "Search on PubMed", url: searchURL)
            }

            NavigationLink {
                LearnSourcesView()
            } label: {
                Text("Sources & References")
                    .font(.caption.weight(.semibold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.accentColor.opacity(0.08), in: .rect(cornerRadius: 12))
    }

    private func referenceLink(_ title: String, detail: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(alignment: .top, spacing: 6) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .multilineTextAlignment(.leading)
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                Image(systemName: "arrow.up.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .accessibilityHint("Opens in your browser")
    }

    /// PubMed search restricted to StatPearls — built from the title, so it's always on
    /// topic and can't be a fabricated citation.
    static func statPearlsSearchURL(for operationTitle: String) -> URL? {
        var components = URLComponents(string: "https://pubmed.ncbi.nlm.nih.gov/")
        components?.queryItems = [URLQueryItem(name: "term", value: "\(operationTitle) AND statpearls[book]")]
        return components?.url
    }
}

#Preview {
    NavigationStack {
        AIContentNote(
            operationTitle: "Laparoscopic Cholecystectomy",
            references: [
                PrepReference(
                    title: "Laparoscopic Cholecystectomy",
                    source: "StatPearls, NCBI Bookshelf, 2025",
                    url: URL(string: "https://www.ncbi.nlm.nih.gov/books/NBK448145/")!
                ),
            ]
        )
            .padding()
    }
}
