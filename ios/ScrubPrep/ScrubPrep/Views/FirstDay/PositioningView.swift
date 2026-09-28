import SwiftUI

/// An orientation reference for common patient positions (Learn tab) — each position
/// opens a detail sheet, followed by safety topics common to all positions.
struct PositioningView: View {
    @State private var selectedPosition: PatientPosition?
    // See InstrumentsView: start expanded on iPad, where the medium detent is a large
    // centered card and would otherwise push most of the content below the fold.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("The positions you'll see most, what each is for, and what can go wrong.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    Label("Positions", systemImage: "bed.double")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(patientPositions) { position in
                            PatientPositionRow(position: position) {
                                selectedPosition = position
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: .rect(cornerRadius: 16))

                Text("Positioning safety")
                    .font(.title3.weight(.semibold))
                    .padding(.top, 8)
                    .accessibilityAddTraits(.isHeader)

                ForEach(positioningSafetyTopics) { topic in
                    SectionCard(title: topic.title, systemImage: topic.systemImage, items: topic.items)
                }
            }
            .padding()
        }
        .navigationTitle("Positioning")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedPosition) { position in
            PatientPositionDetailSheet(
                position: position,
                initialDetent: horizontalSizeClass == .regular ? .large : .medium
            )
        }
    }
}

#Preview {
    NavigationStack {
        PositioningView()
    }
}
