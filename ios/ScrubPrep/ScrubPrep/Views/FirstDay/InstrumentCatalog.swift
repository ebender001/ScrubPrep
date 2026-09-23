import Foundation

/// One photo of an instrument — `caption` labels which variant it is (e.g. "Curved",
/// "Bookwalter") when an instrument has more than one; `nil` for a single-photo instrument.
struct InstrumentImage: Identifiable {
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
struct InstrumentAttribution {
    let sourceName: String
    let usedWithPermission: Bool
    let productURL: URL?
}

/// One instrument in the Instruments 101 reference. `images` are Assets.xcassets image
/// set names — empty until photos have been added. A row is only tappable once it has
/// at least one image, so there's never a tap that opens an empty sheet. An instrument
/// with multiple images (e.g. curved vs. straight Mayo scissors) shows all of them,
/// each under its own caption, in the same bottom sheet.
struct Instrument: Identifiable {
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

struct InstrumentCategory: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let instruments: [Instrument]
}

let instrumentCategories: [InstrumentCategory] = [
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
                ],
                attribution: InstrumentAttribution(
                    sourceName: "Scanlan International",
                    usedWithPermission: true,
                    productURL: URL(string: "https://www.scanlaninternational.com/product/7007-204sc/")
                )
            ),
            Instrument(
                name: "Iris scissors",
                description: "Small, fine scissors for precise cutting of delicate tissue or sutures.",
                images: [InstrumentImage("iris-scissors")],
                attribution: InstrumentAttribution(
                    sourceName: "Scanlan International",
                    usedWithPermission: true,
                    productURL: URL(string: "https://www.scanlaninternational.com/product/7007-288sc/")
                )
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
                images: [InstrumentImage("debakey-forceps")],
                attribution: InstrumentAttribution(
                    sourceName: "Scanlan International",
                    usedWithPermission: true,
                    productURL: URL(string: "https://www.scanlaninternational.com/product/4004-42/")
                )
            ),
            Instrument(
                name: "Adson forceps",
                description: "Toothed forceps for grasping skin during closure.",
                images: [InstrumentImage("adson-forceps")],
                attribution: InstrumentAttribution(
                    sourceName: "Scanlan International",
                    usedWithPermission: true,
                    productURL: URL(string: "https://www.scanlaninternational.com/product/4004-27/")
                )
            ),
            Instrument(
                name: "Allis clamp",
                description: "Grasps and holds tissue with minimal crush injury.",
                images: [InstrumentImage("allis-clamp")],
                attribution: InstrumentAttribution(
                    sourceName: "Scanlan International",
                    usedWithPermission: true,
                    productURL: URL(string: "https://www.scanlaninternational.com/product/4635-06/")
                )
            ),
            Instrument(
                name: "Babcock clamp",
                description: "Gently grasps bowel or other delicate structures.",
                images: [InstrumentImage("babcock-clamp")]
            ),
            Instrument(
                name: "Gerald forceps",
                description: "Fine-tipped forceps for delicate tissue handling, often with a platform tip for microsurgical work.",
                images: [InstrumentImage("gerald-forceps")],
                attribution: InstrumentAttribution(
                    sourceName: "Scanlan International",
                    usedWithPermission: true,
                    productURL: URL(string: "https://www.scanlaninternational.com/product/4004-240/")
                )
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
                images: [InstrumentImage("ryder-needle-holder")],
                attribution: InstrumentAttribution(
                    sourceName: "Scanlan International",
                    usedWithPermission: true,
                    productURL: URL(string: "https://www.scanlaninternational.com/product/6006-29/")
                )
            ),
            Instrument(
                name: "Castroviejo needle holder",
                description: "A spring-loaded, palm-controlled needle holder used for fine or microsurgical suturing.",
                images: [InstrumentImage("castroviejo-needle-holder")],
                attribution: InstrumentAttribution(
                    sourceName: "Scanlan International",
                    usedWithPermission: true,
                    productURL: URL(string: "https://www.scanlaninternational.com/product/6006-56-3/")
                )
            ),
        ]
    ),
]
