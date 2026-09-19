import SwiftUI

/// Shown once every question in the round has been answered — offers "Go Again" (a
/// fresh set of 5, up to the session cap) or "Done".
struct RapidFireCompletedView: View {
    let questionCount: Int
    let caseTitle: String
    let canGoAgain: Bool
    let onGoAgain: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)
            Text("Ready to scrub.")
                .font(.title3.weight(.semibold))
            Text("You reviewed \(questionCount) high-yield questions for \(caseTitle).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if !canGoAgain {
                Text("That's the full \(RapidFireViewModel.maxTotalQuestions)-question review for this case.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                if canGoAgain {
                    Button(action: onGoAgain) {
                        Text("Go Again")
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
                } else {
                    Button(action: onDone) {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RapidFireCompletedView(
        questionCount: 5,
        caseTitle: "Laparoscopic Cholecystectomy",
        canGoAgain: true,
        onGoAgain: {},
        onDone: {}
    )
}
