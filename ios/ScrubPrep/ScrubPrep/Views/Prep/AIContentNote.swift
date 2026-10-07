import SwiftUI

/// Discloses that a screen's medical content is AI-generated (App Store guideline 1.4.1).
/// Each screen showing it also shows the case's `PrepReferencesCard`, which cites the
/// operation itself.
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

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.accentColor.opacity(0.08), in: .rect(cornerRadius: 12))
    }
}

#Preview {
    AIContentNote()
        .padding()
}
