import SwiftUI

/// The Pimp Me / Rapid Fire / First Day cards on the Home screen.
struct ActionCard: View {
    let title: String
    let subtitle: String
    let description: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    ActionCard(
        title: "Pimp Me",
        subtitle: "Test me before I scrub.",
        description: "Interactive questions tailored to your case.",
        systemImage: "flame.fill",
        tint: .orange
    )
    .padding()
}
