import SwiftUI

/// The end-of-session readiness summary, shown once every question in a difficulty has
/// been answered.
struct PimpMeSummaryView: View {
    let summary: PimpSummary
    let prepTitle: String
    let allDifficultiesCompleted: Bool
    let onChooseAnotherDifficulty: () -> Void
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Session Complete")
                        .font(.title3.weight(.semibold))
                    Text(prepTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                SectionCard(title: "You're strong on", systemImage: "checkmark.seal.fill", items: summary.strong)
                SectionCard(title: "Review before you scrub", systemImage: "book.closed.fill", items: summary.review)
                SectionCard(title: "Two-minute review", systemImage: "clock.fill", items: summary.twoMinuteReview)

                if allDifficultiesCompleted {
                    Button(action: onDone) {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: onChooseAnotherDifficulty) {
                        Text("Choose Another Difficulty")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: onDone) {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }
}

#Preview {
    PimpMeSummaryView(
        summary: PimpSummary(
            strong: ["Indications for surgery", "Basic operative sequence"],
            review: ["Arterial anatomy", "Complication management"],
            twoMinuteReview: ["Review the key anatomic landmarks before you scrub in."]
        ),
        prepTitle: "Laparoscopic Cholecystectomy",
        allDifficultiesCompleted: false,
        onChooseAnotherDifficulty: {},
        onDone: {}
    )
}
