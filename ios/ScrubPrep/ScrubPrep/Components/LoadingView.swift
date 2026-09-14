import Combine
import SwiftUI

/// Rotating status messages during AI generation (spec §19) — never a bare spinner.
struct LoadingView: View {
    let title: String
    let messages: [String]

    @State private var messageIndex = 0

    private let timer = Timer.publish(every: 1.6, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(title)
                .font(.headline)
            if !messages.isEmpty {
                Text(messages[messageIndex])
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
                    .animation(.easeInOut, value: messageIndex)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(timer) { _ in
            guard !messages.isEmpty else { return }
            messageIndex = (messageIndex + 1) % messages.count
        }
    }
}

#Preview {
    LoadingView(
        title: "Preparing your case…",
        messages: ["Reviewing the operation", "Identifying key anatomy", "Finding likely questions", "Building your prep"]
    )
}
