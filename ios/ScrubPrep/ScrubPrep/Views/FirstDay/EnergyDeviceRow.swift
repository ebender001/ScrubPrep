import SwiftUI

/// One row in the Energy devices list — generic name, brand names as secondary text, and
/// a one-line summary. Always tappable, opening `EnergyDeviceDetailSheet`.
struct EnergyDeviceRow: View {
    let device: EnergyDevice
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 5, height: 5)
                    .padding(.top, 7)
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.subheadline.weight(.semibold))
                    if let brandNames = device.brandNames {
                        Text(brandNames)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(device.summary)
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
    EnergyDeviceRow(device: energyDevices[0], onSelect: {})
        .padding()
}
