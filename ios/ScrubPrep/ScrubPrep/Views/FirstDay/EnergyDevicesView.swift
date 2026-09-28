import SwiftUI

/// An orientation reference for the energy devices used in the OR (Learn tab) — the
/// devices themselves, each opening a detail sheet, then safety topics common to all.
struct EnergyDevicesView: View {
    @State private var selectedDevice: EnergyDevice?
    // See InstrumentsView: start expanded on iPad, where the medium detent is a large
    // centered card and would otherwise push most of the content below the fold.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("What each device does and when you'll see it — plus the safety issues they all share.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    Label("Devices", systemImage: "bolt")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(energyDevices) { device in
                            EnergyDeviceRow(device: device) {
                                selectedDevice = device
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: .rect(cornerRadius: 16))

                Text("Safety for all energy devices")
                    .font(.title3.weight(.semibold))
                    .padding(.top, 8)
                    .accessibilityAddTraits(.isHeader)

                ForEach(energySafetyTopics) { topic in
                    SectionCard(title: topic.title, systemImage: topic.systemImage, items: topic.items)
                }
            }
            .padding()
        }
        .navigationTitle("Energy devices")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedDevice) { device in
            EnergyDeviceDetailSheet(
                device: device,
                initialDetent: horizontalSizeClass == .regular ? .large : .medium
            )
        }
    }
}

#Preview {
    NavigationStack {
        EnergyDevicesView()
    }
}
