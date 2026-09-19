import SwiftUI

/// The scrollable OR Prep display (spec §6) — concise enough to review in ~10-15 minutes.
struct PrepView: View {
    let caseDescription: String
    let prep: ORPrep

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(prep.caseSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                SectionCard(title: "Why are we operating?", systemImage: "questionmark.circle", items: prep.whyOperating)
                SectionCard(title: "Anatomy I need to know", systemImage: "figure.stand", items: prep.anatomy)
                SectionCard(title: "Operation in 60 seconds", systemImage: "clock", items: prep.operationOverview)
                SectionCard(title: "What should I watch for?", systemImage: "eye", items: prep.thingsToWatch)
                SectionCard(title: "What could go wrong?", systemImage: "exclamationmark.triangle", items: prep.complications)
                SectionCard(title: "Know these 5 things", systemImage: "star.fill", items: prep.mustKnow)

                if !prep.likelyQuestions.isEmpty {
                    PrepLikelyQuestionsCard(questions: prep.likelyQuestions)
                }

                PrepActionButtons(caseDescription: caseDescription, prep: prep)
            }
            .padding()
        }
        .navigationTitle(prep.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrepView(caseDescription: "Lap chole for acute cholecystitis", prep: .mockLapChole)
    }
}
