import SwiftUI

/// One row in the Positioning list — name, alternate names as secondary text, and a
/// one-line summary. Always tappable, opening `PatientPositionDetailSheet`.
struct PatientPositionRow: View {
    let position: PatientPosition
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 5, height: 5)
                    .padding(.top, 7)
                VStack(alignment: .leading, spacing: 2) {
                    Text(position.name)
                        .font(.subheadline.weight(.semibold))
                    if let alternateNames = position.alternateNames {
                        Text(alternateNames)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(position.summary)
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
    PatientPositionRow(position: patientPositions[0], onSelect: {})
        .padding()
}
