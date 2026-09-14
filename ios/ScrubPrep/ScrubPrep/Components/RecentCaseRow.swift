import SwiftUI

/// One row in the Home screen's "Recent Cases" list.
struct RecentCaseRow: View {
    let scrubCase: ScrubCase
    let onReview: () -> Void
    let onPimpMe: () -> Void

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(scrubCase.prep.title)
                .font(.subheadline.weight(.semibold))
            Text(Self.dateFormatter.string(from: scrubCase.createdAt))
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button("Review", action: onReview)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button("Pimp Me", action: onPimpMe)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Spacer()
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    RecentCaseRow(scrubCase: ScrubCase(caseDescription: "Lap chole", prep: .mockLapChole), onReview: {}, onPimpMe: {})
        .padding()
}
