import SwiftUI

/// The bottom sheet shown when tapping an energy device — how it works, when it's used,
/// safety points, and questions you might be asked.
struct EnergyDeviceDetailSheet: View {
    let device: EnergyDevice
    @State private var detent: PresentationDetent

    init(device: EnergyDevice, initialDetent: PresentationDetent) {
        self.device = device
        self._detent = State(initialValue: initialDetent)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.title3.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                    if let brandNames = device.brandNames {
                        Text(brandNames)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(device.howItWorks)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)

                SectionCard(title: "When it's used", systemImage: "stethoscope", items: device.whenUsed)
                SectionCard(title: "Safety", systemImage: "exclamationmark.triangle", items: device.safetyPoints)

                if !device.questions.isEmpty {
                    PrepLikelyQuestionsCard(title: "What you might be asked", questions: device.questions)
                }
            }
            .padding()
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    Text("Energy devices")
        .sheet(isPresented: .constant(true)) {
            EnergyDeviceDetailSheet(device: energyDevices[0], initialDetent: .large)
        }
}
