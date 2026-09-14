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
