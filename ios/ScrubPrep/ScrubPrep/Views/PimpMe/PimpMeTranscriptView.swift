import SwiftUI

/// Read-only review of a previously-completed difficulty's saved transcript and summary.
struct PimpMeTranscriptView: View {
    let difficulty: PimpDifficulty
    let transcript: [PimpTurn]
    let summary: PimpSummary
    let prepTitle: String
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("\(difficulty.displayName) — Completed", systemImage: "checkmark.seal.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.green)
                    Text(prepTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(transcript) { turn in
                    PimpMeFeedbackCard(turn: turn)
                }

                SectionCard(title: "You're strong on", systemImage: "checkmark.seal.fill", items: summary.strong)
                SectionCard(title: "Review before you scrub", systemImage: "book.closed.fill", items: summary.review)
                SectionCard(title: "Two-minute review", systemImage: "clock.fill", items: summary.twoMinuteReview)

                Button(action: onBack) {
                    Text("Back to Difficulties")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

#Preview {
    PimpMeTranscriptView(
        difficulty: .typical,
        transcript: [
            PimpTurn(
                question: "What structures define the hepatocystic triangle?",
                answer: "Cystic duct, common hepatic duct, and the liver edge.",
                assessment: .correct,
                feedback: "Good — you're on the right track.",
                teachingPoint: "Name the specific structures, not just the general area."
            ),
        ],
        summary: PimpSummary(
            strong: ["Indications for surgery"],
            review: ["Arterial anatomy"],
            twoMinuteReview: ["Review the key anatomic landmarks before you scrub in."]
        ),
        prepTitle: "Laparoscopic Cholecystectomy",
        onBack: {}
    )
}
