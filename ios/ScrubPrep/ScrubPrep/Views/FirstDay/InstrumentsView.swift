import SwiftUI

private let instrumentTopics: [LearnTopic] = [
    LearnTopic(
        title: "Cutting",
        systemImage: "scissors",
        items: [
            "Scalpel (Bard-Parker) — the primary tool for skin and tissue incisions.",
            "Metzenbaum scissors — fine scissors for dissecting delicate tissue.",
            "Mayo scissors — heavier scissors for cutting sutures and tougher tissue.",
        ]
    ),
    LearnTopic(
        title: "Grasping & Holding",
        systemImage: "hand.raised",
        items: [
            "DeBakey forceps — atraumatic forceps for handling delicate tissue and vessels.",
            "Adson forceps — toothed forceps for grasping skin during closure.",
            "Allis clamp — grasps and holds tissue with minimal crush injury.",
            "Babcock clamp — gently grasps bowel or other delicate structures.",
        ]
    ),
    LearnTopic(
        title: "Clamping & Hemostasis",
        systemImage: "bolt.heart",
        items: [
            "Kelly clamp — general-purpose clamp for grasping tissue or vessels.",
            "Mosquito clamp — small clamp for fine hemostasis.",
            "Right-angle clamp — used to dissect around and encircle structures.",
        ]
    ),
    LearnTopic(
        title: "Retracting",
        systemImage: "rectangle.expand.vertical",
        items: [
            "Army-Navy retractor — handheld retractor for shallow wounds.",
            "Richardson retractor — wide-bladed retractor for deeper exposure.",
            "Self-retaining retractor (Bookwalter, Balfour) — holds a wound open hands-free.",
        ]
    ),
    LearnTopic(
        title: "Suturing",
        systemImage: "link",
        items: [
            "Needle driver — holds and passes the needle during suturing.",
            "Suture scissors — cuts suture after knot tying.",
            "Toothed (Adson) forceps are commonly used to stabilize tissue while suturing.",
        ]
    ),
]

/// A quick reference for the instruments most often called for during a case (Learn tab).
struct InstrumentsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("A quick reference for the instruments you'll hear called for most often.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(instrumentTopics) { topic in
                    SectionCard(title: topic.title, systemImage: topic.systemImage, items: topic.items)
                }
            }
            .padding()
        }
        .navigationTitle("Instruments 101")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        InstrumentsView()
    }
}
