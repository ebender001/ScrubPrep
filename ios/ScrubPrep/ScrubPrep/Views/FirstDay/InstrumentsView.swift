import SwiftUI

/// A quick reference for the instruments most often called for during a case (Learn tab).
/// An instrument with at least one photo (see `Instrument.images`) is tappable, bringing
/// up a bottom sheet with its image(s), name, and description.
struct InstrumentsView: View {
    @State private var selectedInstrument: Instrument?
    // On iPad, a sheet's "medium" detent is a much bigger absolute sheet (iPadOS
    // presents it as a centered card, not an edge-to-edge half-screen like iPhone) —
    // but the instrument image still fills that available space first, pushing the
    // name/description below the fold and forcing an extra drag-to-expand every time.
    // Starting expanded on regular width avoids that; iPhone keeps the original medium
    // default, where it already fits.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("A quick reference for the instruments you'll hear called for most often.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(instrumentCategories) { category in
                    InstrumentCategoryCard(category: category) { instrument in
                        selectedInstrument = instrument
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Instruments 101")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedInstrument) { instrument in
            InstrumentDetailSheet(
                instrument: instrument,
                initialDetent: horizontalSizeClass == .regular ? .large : .medium
            )
        }
    }
}

#Preview {
    NavigationStack {
        InstrumentsView()
    }
}
