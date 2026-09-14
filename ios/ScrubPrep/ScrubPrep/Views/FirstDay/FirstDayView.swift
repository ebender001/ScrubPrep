import SwiftUI

private struct FirstDayTopic: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let items: [String]
}

private let firstDayTopics: [FirstDayTopic] = [
    FirstDayTopic(
        title: "Before Rounds",
        systemImage: "sunrise",
        items: [
            "Arrive early enough to review your patients before the team gathers.",
            "Know overnight events.",
            "Vitals, intake/output, diet, and bowel function.",
            "Pain control and ambulation status.",
            "Wounds and drains.",
            "Relevant labs.",
            "Prophylaxis (DVT, etc.).",
            "Disposition issues (what's needed before discharge).",
        ]
    ),
    FirstDayTopic(
        title: "Presenting on Rounds",
        systemImage: "person.wave.2",
        items: [
            "Identify the patient and post-op day.",
            "Overnight events and how the patient is feeling.",
            "Vitals and key trends (fever, tachycardia, urine output).",
            "Pertinent exam findings (wound, abdomen, lungs).",
            "Relevant labs and imaging.",
            "Diet, activity, lines/drains/tubes status.",
            "Assessment and plan for the day.",
        ]
    ),
    FirstDayTopic(
        title: "Going to the OR",
        systemImage: "arrow.right.square",
        items: [
            "Know where to go and get there early.",
            "Introduce yourself to the team.",
            "Review the patient's history before the case.",
            "Know the operation being performed.",
            "Meet the OR team — surgeon, anesthesia, nursing, techs.",
        ]
    ),
    FirstDayTopic(
        title: "Scrubbing",
        systemImage: "hands.and.sparkles",
        items: [
            "Surgical hand preparation.",
            "Entering the OR without breaking sterility.",
            "Gowning and gloving.",
            "Maintaining sterility throughout the case.",
            "Follow your institution's specific sterile technique policies and the instructions of OR personnel — this isn't a substitute for that training.",
        ]
    ),
    FirstDayTopic(
        title: "OR Etiquette",
        systemImage: "person.2.badge.gearshape",
        items: [
            "Introduce yourself to the team.",
            "Ask where you should stand.",
            "Don't touch anything unless you know it's sterile.",
            "If you think you've contaminated yourself, say so immediately.",
            "Questions are usually welcome — choose appropriate moments.",
            "Don't take correction personally.",
            "Help when appropriate, and remain engaged.",
        ]
    ),
    FirstDayTopic(
        title: "When You Don't Know an Answer",
        systemImage: "questionmark.bubble",
        items: [
            "It's okay to say you don't know.",
            "Try: \u{201C}I'm not sure, but I think\u{2026}\u{201D} when you have a reasonable thought process.",
            "Don't bluff — reasoning out loud is far better than guessing with false confidence.",
        ]
    ),
]

/// Static onboarding content for students new to the surgery rotation (spec §10).
struct FirstDayView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Practical answers to what medical students worry about most before their first day on surgery.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(firstDayTopics) { topic in
                    SectionCard(title: topic.title, systemImage: topic.systemImage, items: topic.items)
                }
            }
            .padding()
        }
        .navigationTitle("First Day")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FirstDayView()
    }
}
