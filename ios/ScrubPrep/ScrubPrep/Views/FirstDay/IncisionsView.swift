import SwiftUI

/// An orientation reference for common surgical incisions (Learn tab), grouped by body
/// region like Instruments 101 — each incision opens a detail sheet — followed by topics
/// common to all incisions.
struct IncisionsView: View {
    @State private var selectedIncision: Incision?
    // See InstrumentsView: start expanded on iPad, where the medium detent is a large
    // centered card and would otherwise push most of the content below the fold.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Where common incisions go, what they're used for, and what lies underneath.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(incisionRegions) { region in
                    VStack(alignment: .leading, spacing: 10) {
                        Label(region.title, systemImage: region.systemImage)
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(region.incisions) { incision in
                                IncisionRow(incision: incision) {
                                    selectedIncision = incision
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: .rect(cornerRadius: 16))
                }

                Text("Incision basics")
                    .font(.title3.weight(.semibold))
                    .padding(.top, 8)
                    .accessibilityAddTraits(.isHeader)

                ForEach(incisionGeneralTopics) { topic in
                    SectionCard(title: topic.title, systemImage: topic.systemImage, items: topic.items)
                }
            }
            .padding()
        }
        .navigationTitle("Incisions")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedIncision) { incision in
            IncisionDetailSheet(
                incision: incision,
                initialDetent: horizontalSizeClass == .regular ? .large : .medium
            )
        }
    }
}

#Preview {
    NavigationStack {
        IncisionsView()
    }
}
