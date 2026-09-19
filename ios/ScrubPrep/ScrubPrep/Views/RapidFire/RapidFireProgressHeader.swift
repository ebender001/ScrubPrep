import SwiftUI

/// Progress bar + "Question X of Y" caption shown above the current Rapid Fire question.
struct RapidFireProgressHeader: View {
    let currentIndex: Int
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: Double(currentIndex), total: Double(max(totalCount, 1)))
                .tint(.yellow)
            Text("Question \(currentIndex + 1) of \(totalCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    RapidFireProgressHeader(currentIndex: 1, totalCount: 5)
        .padding()
}
