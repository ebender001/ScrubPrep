import SwiftUI

/// Discloses that a screen's medical content is AI-generated and points to the cited
/// Learn sources (App Store guideline 1.4.1). Must be shown inside a NavigationStack.
struct AIContentNote: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text("AI-generated for study. Verify with your clinical team and standard references.")
            } icon: {
                Image(systemName: "sparkles")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

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
}

#Preview {
    NavigationStack {
        AIContentNote()
            .padding()
    }
}
