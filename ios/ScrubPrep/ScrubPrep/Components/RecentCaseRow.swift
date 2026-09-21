import SwiftUI

/// One row in the Home screen's "Recent Cases" list.
struct RecentCaseRow: View {
    let scrubCase: ScrubCase
    let onReview: () -> Void
    let onPimpMe: () -> Void
    let onRapidFire: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(scrubCase.prep.title)
                .font(.subheadline.weight(.semibold))
            Text(scrubCase.createdAt, format: .dateTime.month(.abbreviated).day().year())
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button("Review", action: onReview)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button("Quiz Me", action: onPimpMe)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button("Rapid Fire", action: onRapidFire)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Spacer()
            }
        }
        .padding()
        .background(.thinMaterial, in: .rect(cornerRadius: 14))
    }
}

#Preview {
    RecentCaseRow(
        scrubCase: ScrubCase(
            id: "preview",
            caseDescription: "Lap chole",
            prep: .mockLapChole,
            createdAt: Date(),
            updatedAt: Date(),
            lastReviewedAt: nil
        ),
        onReview: {},
        onPimpMe: {},
        onRapidFire: {}
    )
    .padding()
}
