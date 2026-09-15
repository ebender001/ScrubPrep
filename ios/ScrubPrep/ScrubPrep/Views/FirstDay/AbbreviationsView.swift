import SwiftUI

private let abbreviationTopics: [LearnTopic] = [
    LearnTopic(
        title: "Patient Status & Orders",
        systemImage: "list.clipboard",
        items: [
            "NPO — nothing by mouth.",
            "PRN — as needed.",
            "DVT ppx — deep vein thrombosis prophylaxis.",
            "PO / IV / IM — by mouth / intravenous / intramuscular.",
            "I&O — intake and output.",
        ]
    ),
    LearnTopic(
        title: "Vitals & Labs",
        systemImage: "waveform.path.ecg",
        items: [
            "BP / HR / RR / SpO2 — blood pressure / heart rate / respiratory rate / oxygen saturation.",
            "Tmax — maximum recorded temperature.",
            "Hgb / Hct — hemoglobin / hematocrit.",
            "WBC — white blood cell count.",
            "Cr / BUN — creatinine / blood urea nitrogen (kidney function).",
            "Na / K — sodium / potassium.",
        ]
    ),
    LearnTopic(
        title: "Perioperative",
        systemImage: "clock.arrow.circlepath",
        items: [
            "Pre-op / intra-op / post-op — before, during, and after surgery.",
            "POD# — post-operative day number.",
            "EBL — estimated blood loss.",
            "NGT — nasogastric tube.",
            "Foley — indwelling urinary catheter.",
        ]
    ),
    LearnTopic(
        title: "Documentation",
        systemImage: "doc.text",
        items: [
            "H&P — history and physical.",
            "A&P — assessment and plan.",
            "ROS — review of systems.",
            "WNL — within normal limits.",
            "NKDA — no known drug allergies.",
            "c/o — complains of.",
            "s/p — status post (after a prior procedure or event).",
            "DC / D/C — discharge, or discontinue (context-dependent).",
        ]
    ),
    LearnTopic(
        title: "OR-Specific",
        systemImage: "stethoscope",
        items: [
            "Time-out — final safety check before incision (site, procedure, patient verification).",
            "Sterile field — the area maintained free of contamination during surgery.",
            "Circulator — the non-sterile OR nurse managing the room.",
            "Scrub tech/nurse — the sterile team member managing instruments.",
            "CVL / A-line — central venous line / arterial line.",
        ]
    ),
]

/// A glossary of common OR and surgical abbreviations/shorthand (Learn tab).
struct AbbreviationsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Shorthand you'll hear on rounds and in the OR — and see in notes and orders.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(abbreviationTopics) { topic in
                    SectionCard(title: topic.title, systemImage: topic.systemImage, items: topic.items)
                }
            }
            .padding()
        }
        .navigationTitle("Abbreviations")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AbbreviationsView()
    }
}
