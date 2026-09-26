import SwiftUI

/// The bottom sheet shown when tapping an instrument with at least one photo — every
/// image shows together (each under its own caption when there's more than one).
struct InstrumentDetailSheet: View {
    let instrument: Instrument
    @State private var detent: PresentationDetent

    init(instrument: Instrument, initialDetent: PresentationDetent) {
        self.instrument = instrument
        self._detent = State(initialValue: initialDetent)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(instrument.images) { image in
                    VStack(alignment: .leading, spacing: 6) {
                        if let caption = image.caption {
                            Text(caption)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        Image(image.assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(.rect(cornerRadius: 16))
                    }
                }
                Text(instrument.name)
                    .font(.title3.weight(.semibold))
                Text(instrument.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let attribution = instrument.attribution {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                        InstrumentAttributionView(attribution: attribution)
                    }
                }
            }
            .padding()
            // Clears the drag indicator, which otherwise crowds the first line.
            .padding(.top, 12)
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        // Opaque — the default translucent sheet at the medium detent lets the list
        // behind it show through the text.
        .presentationBackground(Color(.systemBackground))
    }
}

#Preview {
    InstrumentDetailSheet(
        instrument: Instrument(
            name: "Metzenbaum scissors",
            description: "Fine scissors for dissecting delicate tissue.",
            images: [InstrumentImage("metzenbaum-scissors")]
        ),
        initialDetent: .medium
    )
}
