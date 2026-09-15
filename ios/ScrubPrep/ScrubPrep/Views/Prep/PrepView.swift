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
                    likelyQuestionsCard
                }

                actionButtons
            }
            .padding()
        }
        .navigationTitle(prep.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var likelyQuestionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Likely questions", systemImage: "bubble.left.and.bubble.right")
                .font(.headline)
            ForEach(prep.likelyQuestions) { qa in
                VStack(alignment: .leading, spacing: 3) {
                    Text(qa.question)
                        .font(.subheadline.weight(.medium))
                    Text(qa.answer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            NavigationLink {
                PimpMeView(caseDescription: caseDescription, prep: prep)
            } label: {
                Label("Pimp Me", systemImage: "flame.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)

            NavigationLink {
                RapidFireView(caseDescription: caseDescription, prep: prep)
            } label: {
                Label("Rapid Fire", systemImage: "bolt.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        PrepView(caseDescription: "Lap chole for acute cholecystitis", prep: .mockLapChole)
    }
}
