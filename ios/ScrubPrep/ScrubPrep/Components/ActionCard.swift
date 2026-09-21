import SwiftUI

/// The Pimp Me / Rapid Fire / First Day cards on the Home screen.
struct ActionCard: View {
    let title: String
    let subtitle: String
    let description: String
    let systemImage: String
    let tint: Color
    /// Shown under `description` (e.g. "Unlocks after Prepare Me") when this card is
    /// currently disabled for a reason that isn't obvious from dimming alone. `nil` when
    /// the card has no such condition (e.g. First Day, which is never locked).
    var lockedMessage: String? = nil

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.15), in: .rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let lockedMessage {
                    Label(lockedMessage, systemImage: "lock.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
    }
}

#Preview {
    ActionCard(
        title: "Quiz Me",
        subtitle: "Test me before I scrub.",
        description: "Interactive questions tailored to your case.",
        systemImage: "flame.fill",
        tint: .orange
    )
    .padding()
}
