import SwiftUI

/// One category section on the Instruments 101 screen — a titled card listing every
/// instrument in that category.
struct InstrumentCategoryCard: View {
    let category: InstrumentCategory
    let onSelectInstrument: (Instrument) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(category.title, systemImage: category.systemImage)
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(category.instruments) { instrument in
                    InstrumentRow(instrument: instrument) {
                        onSelectInstrument(instrument)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
    }
}

#Preview {
    InstrumentCategoryCard(category: instrumentCategories[0], onSelectInstrument: { _ in })
        .padding()
}
