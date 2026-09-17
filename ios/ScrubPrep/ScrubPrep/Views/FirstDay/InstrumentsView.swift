import SwiftUI

/// One photo of an instrument — `caption` labels which variant it is (e.g. "Curved",
/// "Bookwalter") when an instrument has more than one; `nil` for a single-photo instrument.
private struct InstrumentImage: Identifiable {
    let id = UUID()
    let assetName: String
    let caption: String?

    init(_ assetName: String, caption: String? = nil) {
        self.assetName = assetName
        self.caption = caption
    }
}

/// Photo credit shown at the bottom of an instrument's detail sheet, when the photo
/// isn't the app's own and requires attribution. Reusable across any Instruments 101
/// entry — not specific to any one source or instrument. `productURL` is optional:
/// some supplied photos may not have a linkable product page.
private struct InstrumentAttribution {
    let sourceName: String
    let usedWithPermission: Bool
    let productURL: URL?
}

/// One instrument in the Instruments 101 reference. `images` are Assets.xcassets image
/// set names — empty until photos have been added. A row is only tappable once it has
/// at least one image, so there's never a tap that opens an empty sheet. An instrument
/// with multiple images (e.g. curved vs. straight Mayo scissors) shows all of them,
/// each under its own caption, in the same bottom sheet.
private struct Instrument: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let images: [InstrumentImage]
    let attribution: InstrumentAttribution?

    init(name: String, description: String, images: [InstrumentImage] = [], attribution: InstrumentAttribution? = nil) {
        self.name = name
        self.description = description
        self.images = images
        self.attribution = attribution
    }
}

private struct InstrumentCategory: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let instruments: [Instrument]
}

private let instrumentCategories: [InstrumentCategory] = [
    InstrumentCategory(
        title: "Cutting",
        systemImage: "scissors",
        instruments: [
            Instrument(
                name: "Scalpel (Bard-Parker)",
                description: "The primary tool for skin and tissue incisions.",
                images: [InstrumentImage("scalpel-bard-parker")]
            ),
            Instrument(
                name: "Metzenbaum scissors",
                description: "Fine scissors for dissecting delicate tissue.",
                images: [InstrumentImage("metzenbaum-scissors")],
                attribution: InstrumentAttribution(
                    sourceName: "Scanlan International",
                    usedWithPermission: true,
                    productURL: URL(string: "https://www.scanlaninternational.com/product/7007-216-2sc/")
                )
            ),
            Instrument(
                name: "Mayo scissors",
                description: "Heavier scissors for cutting sutures and tougher tissue.",
                images: [
                    InstrumentImage("mayo-scissors-curved", caption: "Curved"),
                    InstrumentImage("mayo-scissors-straight", caption: "Straight"),
                ]
            ),
            Instrument(
                name: "Iris scissors",
                description: "Small, fine scissors for precise cutting of delicate tissue or sutures.",
                images: [InstrumentImage("iris-scissors")]
            ),
        ]
    ),
    InstrumentCategory(
        title: "Grasping & Holding",
        systemImage: "hand.raised",
        instruments: [
            Instrument(
                name: "DeBakey forceps",
                description: "Atraumatic forceps for handling delicate tissue and vessels.",
                images: [InstrumentImage("debakey-forceps")]
            ),
            Instrument(
                name: "Adson forceps",
                description: "Toothed forceps for grasping skin during closure.",
                images: [InstrumentImage("adson-forceps")]
            ),
            Instrument(
                name: "Allis clamp",
                description: "Grasps and holds tissue with minimal crush injury.",
                images: [InstrumentImage("allis-clamp")]
            ),
            Instrument(
                name: "Babcock clamp",
                description: "Gently grasps bowel or other delicate structures.",
                images: [InstrumentImage("babcock-clamp")]
            ),
            Instrument(
                name: "Gerald forceps",
                description: "Fine-tipped forceps for delicate tissue handling, often with a platform tip for microsurgical work.",
                images: [InstrumentImage("gerald-forceps")]
            ),
        ]
    ),
    InstrumentCategory(
        title: "Clamping & Hemostasis",
        systemImage: "bolt.heart",
        instruments: [
            Instrument(
                name: "Kelly clamp",
                description: "General-purpose clamp for grasping tissue or vessels.",
                images: [InstrumentImage("kelly-clamp")]
            ),
            Instrument(
                name: "Mosquito clamp",
                description: "Small clamp for fine hemostasis.",
                images: [InstrumentImage("mosquito-clamp")]
            ),
            Instrument(
                name: "Right-angle clamp",
                description: "Used to dissect around and encircle structures.",
                images: [InstrumentImage("right-angle-clamp")]
            ),
        ]
    ),
    InstrumentCategory(
        title: "Retracting",
        systemImage: "rectangle.expand.vertical",
        instruments: [
            Instrument(
                name: "Army-Navy retractor",
                description: "Handheld retractor for shallow wounds.",
                images: [InstrumentImage("army-navy-retractor")]
            ),
            Instrument(
                name: "Richardson retractor",
                description: "Wide-bladed retractor for deeper exposure.",
                images: [InstrumentImage("richardson-retractor")]
            ),
            Instrument(
                name: "Self-retaining retractor (Bookwalter, Balfour)",
                description: "Holds a wound open hands-free.",
                images: [
                    InstrumentImage("self-retaining-retractor-bookwalter", caption: "Bookwalter"),
                    InstrumentImage("self-retaining-retractor-balfour", caption: "Balfour"),
                ]
            ),
            Instrument(
                name: "Weitlaner retractor",
                description: "Self-retaining retractor with sharp or blunt prongs, commonly used for smaller or superficial wounds.",
                images: [InstrumentImage("weitlaner-retractor")]
            ),
        ]
    ),
    InstrumentCategory(
        title: "Suturing",
        systemImage: "link",
        instruments: [
            Instrument(
                name: "Needle driver",
                description: "Holds and passes the needle during suturing.",
                images: [InstrumentImage("needle-driver")]
            ),
            Instrument(
                name: "Ryder needle holder",
                description: "A slender needle holder favored for fine, delicate suturing.",
                images: [InstrumentImage("ryder-needle-holder")]
            ),
            Instrument(
                name: "Castroviejo needle holder",
                description: "A spring-loaded, palm-controlled needle holder used for fine or microsurgical suturing.",
                images: [InstrumentImage("castroviejo-needle-holder")]
            ),
        ]
    ),
]

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
                    categoryCard(category)
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
        if instrument.images.isEmpty {
            instrumentRowContent(instrument, isTappable: false)
        } else {
            Button {
                selectedInstrument = instrument
            } label: {
                instrumentRowContent(instrument, isTappable: true)
            }
            .buttonStyle(.plain)
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

/// The bottom sheet shown when tapping an instrument with at least one photo — every
/// image shows together (each under its own caption when there's more than one).
private struct InstrumentDetailSheet: View {
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
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
    }
}

/// Small, subordinate photo-credit line for an instrument photo supplied by an outside
/// source — deliberately understated so it never competes with the instrument's name or
/// educational description above it. Reusable for any Instruments 101 entry with an
/// `InstrumentAttribution`, not tied to any particular source or instrument.
private struct InstrumentAttributionView: View {
    let attribution: InstrumentAttribution

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            (
                Text("Image courtesy of ")
                    .foregroundStyle(.secondary)
                + Text(attribution.sourceName)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            )
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
    NavigationStack {
        InstrumentsView()
    }
}
