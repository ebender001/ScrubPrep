import SwiftUI

/// Progress bar + "Question X of Y" caption shown above the current Pimp Me question.
struct PimpMeProgressHeader: View {
    let progress: PimpProgress

    var body: some View {
        let questionNumber = min(progress.index + 1, progress.total)
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: Double(progress.index), total: Double(max(progress.total, 1)))
                .tint(Color.accentColor)
            Text("Question \(questionNumber) of \(progress.total)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    PimpMeProgressHeader(progress: PimpProgress(index: 1, total: 5))
        .padding()
}
