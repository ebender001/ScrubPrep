import SwiftUI

/// "References for this operation" on the prep screen — the prep's verified StatPearls
/// references (real articles the backend found through NCBI; see ORPrep.references), or,
/// when there are none (older saved cases, or no StatPearls article fits), searches of the
/// NCBI Bookshelf and PubMed review articles. Those cast a wider net than StatPearls on
/// purpose: when the backend found no StatPearls match, a StatPearls search would come up
/// empty too. Styled like the screen's content cards, apart from the tinted AI-content
/// note above it.
struct PrepReferencesCard: View {
    let operationTitle: String
    let references: [PrepReference]?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("References for this operation", systemImage: "book.closed")
                .font(.headline)

            if let references, !references.isEmpty {
                ForEach(references) { reference in
                    LearnSourceRow(source: LearnSource(title: reference.title, detail: reference.source, url: reference.url))
                }
            } else {
                // `nil` means this prep was never looked up (saved before references
                // existed); empty means a lookup ran and found no StatPearls match.
                Text(references == nil
                     ? "Search these sources for this operation:"
                     : "No StatPearls article matched this case. Search these sources instead:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let bookshelfURL = Self.bookshelfSearchURL(for: operationTitle) {
                    LearnSourceRow(source: LearnSource(
                        title: "Search medical textbooks",
                        detail: "NCBI Bookshelf, including StatPearls",
                        url: bookshelfURL
                    ))
                }
                if let reviewsURL = Self.pubMedReviewSearchURL(for: operationTitle) {
                    LearnSourceRow(source: LearnSource(
                        title: "Search review articles",
                        detail: "PubMed, National Library of Medicine",
                        url: reviewsURL
                    ))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
    }

    // Searches are built from the operation's title, so they're always on topic and can't
    // be a fabricated citation.

    static func bookshelfSearchURL(for operationTitle: String) -> URL? {
        var components = URLComponents(string: "https://www.ncbi.nlm.nih.gov/books/")
        components?.queryItems = [URLQueryItem(name: "term", value: operationTitle)]
        return components?.url
    }

    static func pubMedReviewSearchURL(for operationTitle: String) -> URL? {
        var components = URLComponents(string: "https://pubmed.ncbi.nlm.nih.gov/")
        components?.queryItems = [
            URLQueryItem(name: "term", value: operationTitle),
            URLQueryItem(name: "filter", value: "pubt.review"),
        ]
        return components?.url
    }
}

#Preview("With references") {
    PrepReferencesCard(
        operationTitle: "Carotid Endarterectomy",
        references: [
            PrepReference(
                title: "Carotid Endarterectomy",
                source: "StatPearls, NCBI Bookshelf, 2023",
                url: URL(string: "https://www.ncbi.nlm.nih.gov/books/NBK470582/")!
            ),
        ]
    )
    .padding()
}

#Preview("Search fallback") {
    PrepReferencesCard(operationTitle: "Femoral-Popliteal Bypass", references: [])
        .padding()
}
