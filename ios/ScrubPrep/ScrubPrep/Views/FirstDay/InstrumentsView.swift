import SwiftUI

/// One instrument in the Instruments 101 reference. `imageName` matches an image set
/// in Assets.xcassets (a photo of the instrument) — `nil` until that photo has been
/// added. A row is only tappable once its image exists, so there's never a tap that
/// opens an empty sheet.
private struct Instrument: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let imageName: String?
}

private struct InstrumentCategory: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let instruments: [Instrument]
}

// imageName values are the exact Assets.xcassets image set names to use once each photo
// is added — nil everywhere for now since no photos exist yet.
private let instrumentCategories: [InstrumentCategory] = [
    InstrumentCategory(
        title: "Cutting",
        systemImage: "scissors",
        instruments: [
            Instrument(name: "Scalpel (Bard-Parker)", description: "The primary tool for skin and tissue incisions.", imageName: "scalpel-bard-parker"),
            Instrument(name: "Metzenbaum scissors", description: "Fine scissors for dissecting delicate tissue.", imageName: nil),
            Instrument(name: "Mayo scissors", description: "Heavier scissors for cutting sutures and tougher tissue.", imageName: nil),
        ]
    ),
    InstrumentCategory(
        title: "Grasping & Holding",
        systemImage: "hand.raised",
        instruments: [
            Instrument(name: "DeBakey forceps", description: "Atraumatic forceps for handling delicate tissue and vessels.", imageName: nil),
            Instrument(name: "Adson forceps", description: "Toothed forceps for grasping skin during closure.", imageName: nil),
            Instrument(name: "Allis clamp", description: "Grasps and holds tissue with minimal crush injury.", imageName: nil),
            Instrument(name: "Babcock clamp", description: "Gently grasps bowel or other delicate structures.", imageName: nil),
        ]
    ),
    InstrumentCategory(
        title: "Clamping & Hemostasis",
        systemImage: "bolt.heart",
        instruments: [
            Instrument(name: "Kelly clamp", description: "General-purpose clamp for grasping tissue or vessels.", imageName: nil),
            Instrument(name: "Mosquito clamp", description: "Small clamp for fine hemostasis.", imageName: nil),
            Instrument(name: "Right-angle clamp", description: "Used to dissect around and encircle structures.", imageName: nil),
        ]
    ),
    InstrumentCategory(
        title: "Retracting",
        systemImage: "rectangle.expand.vertical",
        instruments: [
            Instrument(name: "Army-Navy retractor", description: "Handheld retractor for shallow wounds.", imageName: nil),
            Instrument(name: "Richardson retractor", description: "Wide-bladed retractor for deeper exposure.", imageName: nil),
            Instrument(name: "Self-retaining retractor (Bookwalter, Balfour)", description: "Holds a wound open hands-free.", imageName: nil),
        ]
    ),
    InstrumentCategory(
        title: "Suturing",
        systemImage: "link",
        instruments: [
            Instrument(name: "Needle driver", description: "Holds and passes the needle during suturing.", imageName: nil),
            Instrument(name: "Suture scissors", description: "Cuts suture after knot tying.", imageName: nil),
        ]
    ),
]

/// A quick reference for the instruments most often called for during a case (Learn tab).
/// An instrument with a photo (see `Instrument.imageName`) is tappable, bringing up a
/// bottom sheet with its image, name, and description.
struct InstrumentsView: View {
    @State private var selectedInstrument: Instrument?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("A quick reference for the instruments you'll hear called for most often.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(instrumentCategories) { category in
                    categoryCard(category)
                }
            }
            .padding()
        }
        .navigationTitle("Instruments 101")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedInstrument) { instrument in
            InstrumentDetailSheet(instrument: instrument)
        }
    }

    private func categoryCard(_ category: InstrumentCategory) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(category.title, systemImage: category.systemImage)
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(category.instruments) { instrument in
                    instrumentRow(instrument)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func instrumentRow(_ instrument: Instrument) -> some View {
        if instrument.imageName != nil {
            Button {
                selectedInstrument = instrument
            } label: {
                instrumentRowContent(instrument, isTappable: true)
            }
            .buttonStyle(.plain)
        } else {
            instrumentRowContent(instrument, isTappable: false)
        }
    }

    private func instrumentRowContent(_ instrument: Instrument, isTappable: Bool) -> some View {
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

/// The bottom sheet shown when tapping an instrument with a photo.
private struct InstrumentDetailSheet: View {
    let instrument: Instrument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageName = instrument.imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                Text(instrument.name)
                    .font(.title3.weight(.semibold))
                Text(instrument.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NavigationStack {
        InstrumentsView()
    }
}
