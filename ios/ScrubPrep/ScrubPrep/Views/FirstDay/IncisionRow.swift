import SwiftUI

/// One row in an Incisions region card — name, alternate names as secondary text, and a
/// one-line summary. Always tappable, opening `IncisionDetailSheet`.
struct IncisionRow: View {
    let incision: Incision
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 5, height: 5)
                    .padding(.top, 7)
                VStack(alignment: .leading, spacing: 2) {
                    Text(incision.name)
                        .font(.subheadline.weight(.semibold))
                    if let alternateNames = incision.alternateNames {
                        Text(alternateNames)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(incision.summary)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    IncisionRow(incision: incisionRegions[2].incisions[5], onSelect: {})
        .padding()
}
