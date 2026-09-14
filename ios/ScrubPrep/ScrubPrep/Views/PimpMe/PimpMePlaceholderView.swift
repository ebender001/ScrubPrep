import SwiftUI

/// Placeholder destination — the full interactive Pimp Me experience (difficulty picker,
/// one-question-at-a-time flow, adaptive follow-ups) is built in Phase 3 (spec §7-8).
/// This keeps navigation from Home/PrepView functional in the meantime.
struct PimpMePlaceholderView: View {
    let caseDescription: String?
    let prep: ORPrep?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text("Pimp Me")
                .font(.title2.weight(.semibold))
            Text("Interactive oral-questioning is coming in the next build.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let prep {
                Text("Ready for: \(prep.title)")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Pimp Me")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PimpMePlaceholderView(caseDescription: "Lap chole", prep: .mockLapChole)
    }
}
