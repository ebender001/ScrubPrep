import SwiftUI

/// One row in an `InstrumentCategoryCard` — tappable (opening the detail sheet) only if
/// the instrument has at least one photo.
struct InstrumentRow: View {
    let instrument: Instrument
    let onSelect: () -> Void

    var body: some View {
        if instrument.images.isEmpty {
            content(isTappable: false)
        } else {
            Button(action: onSelect) {
                content(isTappable: true)
            }
            .buttonStyle(.plain)
        }
    }

    private func content(isTappable: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 5, height: 5)
                .padding(.top, 7)
            Text("\(instrument.name) — \(instrument.description)")
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            if isTappable {
                Spacer(minLength: 4)
                Image(systemName: "photo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    InstrumentRow(
        instrument: Instrument(
            name: "Metzenbaum scissors",
            description: "Fine scissors for dissecting delicate tissue.",
            images: [InstrumentImage("metzenbaum-scissors")]
        ),
        onSelect: {}
    )
    .padding()
}
