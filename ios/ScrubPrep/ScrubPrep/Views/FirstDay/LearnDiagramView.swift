import SwiftUI

/// A `LearnDiagram` on a Learn detail sheet: optional caption above template-rendered
/// line art on a rounded card. Template rendering makes the art follow the text color
/// in light and dark mode.
struct LearnDiagramView: View {
    let diagram: LearnDiagram
    /// What the diagram shows, for VoiceOver — e.g. "the Supine position".
    let subject: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let caption = diagram.caption {
                Text(caption)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Image(diagram.assetName)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.primary)
                // Caps tall (portrait) art such as incision body outlines so it doesn't
                // fill the sheet; wide position diagrams stay width-limited instead.
                .frame(maxWidth: .infinity, maxHeight: 240)
                .padding()
                .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 16))
                .accessibilityLabel("\(diagram.caption.map { "\($0) diagram" } ?? "Diagram") of \(subject)")
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        LearnDiagramView(diagram: LearnDiagram("position-supine", caption: "Side view"), subject: "the Supine position")
        LearnDiagramView(diagram: LearnDiagram("incision-mcburney"), subject: "the McBurney incision")
    }
    .padding()
}
