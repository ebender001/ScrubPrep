import SwiftUI

/// The "Recent Cases" list on the Home screen — the 5 most recently updated cases.
struct RecentCasesSection: View {
    let recentCases: [ScrubCase]
    let onReview: (ScrubCase) -> Void
    let onPimpMe: (ScrubCase) -> Void
    let onRapidFire: (ScrubCase) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Cases")
                .font(.title3.weight(.semibold))

            ForEach(recentCases.prefix(5)) { scrubCase in
                RecentCaseRow(
                    scrubCase: scrubCase,
                    onReview: { onReview(scrubCase) },
                    onPimpMe: { onPimpMe(scrubCase) },
                    onRapidFire: { onRapidFire(scrubCase) }
                )
            }
        }
    }
}

#Preview {
    RecentCasesSection(
        recentCases: [
            ScrubCase(
                id: "preview",
                caseDescription: "Lap chole",
                prep: .mockLapChole,
                createdAt: Date(),
                updatedAt: Date(),
                lastReviewedAt: nil
            ),
        ],
        onReview: { _ in },
        onPimpMe: { _ in },
        onRapidFire: { _ in }
    )
    .padding()
}
