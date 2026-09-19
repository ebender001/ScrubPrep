import SwiftUI

/// Small, subordinate photo-credit line for an instrument photo supplied by an outside
/// source — deliberately understated so it never competes with the instrument's name or
/// educational description above it. Reusable for any Instruments 101 entry with an
/// `InstrumentAttribution`, not tied to any particular source or instrument.
struct InstrumentAttributionView: View {
    let attribution: InstrumentAttribution

    var body: some View {
        let prefix = Text("Image courtesy of ")
            .foregroundStyle(.secondary)
        let sourceName = Text(attribution.sourceName)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)

        VStack(alignment: .leading, spacing: 2) {
            Text("\(prefix)\(sourceName)")
                .font(.footnote)

            if attribution.usedWithPermission || attribution.productURL != nil {
                HStack(spacing: 4) {
                    if attribution.usedWithPermission {
                        Text("Used with permission")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if attribution.usedWithPermission, attribution.productURL != nil {
                        Text("·")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if let productURL = attribution.productURL {
                        Link(destination: productURL) {
                            HStack(spacing: 2) {
                                Text("View at \(attribution.sourceName)")
                                Image(systemName: "arrow.up.right")
                                    .font(.caption2.weight(.semibold))
                            }
                        }
                        .font(.footnote)
                        .foregroundStyle(Color.accentColor)
                    }
                }
            }
        }
    }
}

#Preview {
    InstrumentAttributionView(
        attribution: InstrumentAttribution(
            sourceName: "Scanlan International",
            usedWithPermission: true,
            productURL: URL(string: "https://www.scanlaninternational.com")
        )
    )
    .padding()
}
