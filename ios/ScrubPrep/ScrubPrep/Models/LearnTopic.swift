import Foundation

/// A single Learn-tab section (e.g. "Cutting Instruments"): a titled, icon-labeled list of
/// short bullets rendered via SectionCard. Shared by FirstDayView, InstrumentsView, and
/// AbbreviationsView so this shape isn't redefined per screen.
struct LearnTopic: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let items: [String]
}

/// One reference diagram on a Learn detail sheet (Positioning, Incisions) — `caption`
/// labels the view ("Side view", "Overhead view") when an entry has more than one; `nil`
/// for an entry with a single diagram. Shown via `LearnDiagramView`.
struct LearnDiagram: Identifiable {
    let id = UUID()
    /// Assets.xcassets image set name — single-color SVG, rendered as a template.
    let assetName: String
    let caption: String?

    init(_ assetName: String, caption: String? = nil) {
        self.assetName = assetName
        self.caption = caption
    }

    /// A side view plus an overhead view, captioned.
    static func sideAndOverhead(_ baseName: String) -> [LearnDiagram] {
        [
            LearnDiagram(baseName, caption: "Side view"),
            LearnDiagram("\(baseName)-overhead", caption: "Overhead view"),
        ]
    }
}
