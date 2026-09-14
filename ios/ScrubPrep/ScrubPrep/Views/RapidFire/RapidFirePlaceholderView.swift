import SwiftUI

/// Placeholder destination — the full 5-question Rapid Fire flow is built in Phase 4
/// (spec §9). This keeps navigation from Home/PrepView functional in the meantime.
struct RapidFirePlaceholderView: View {
    let caseDescription: String?
    let prep: ORPrep?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 44))
                .foregroundStyle(.yellow)
            Text("Rapid Fire")
                .font(.title2.weight(.semibold))
            Text("The 2-minute pre-op review is coming in the next build.")
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
        .navigationTitle("Rapid Fire")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        RapidFirePlaceholderView(caseDescription: "Lap chole", prep: .mockLapChole)
    }
}
