import SwiftUI

/// The answer text field + Submit button in a Pimp Me session.
struct PimpMeAnswerInput: View {
    @Binding var answerText: String
    let isSubmitting: Bool
    var isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Type your answer", text: $answerText, axis: .vertical)
                .lineLimit(4...)
                .focused(isFocused)
                .disabled(isSubmitting)
                .autocorrectionDisabled()
                .padding(8)
                .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 12))

            Button(action: onSubmit) {
                if isSubmitting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                } else {
                    Text("Submit")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSubmitting || answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

private struct PimpMeAnswerInputPreview: View {
    @State private var answerText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        PimpMeAnswerInput(answerText: $answerText, isSubmitting: false, isFocused: $isFocused, onSubmit: {})
            .padding()
    }
}

#Preview {
    PimpMeAnswerInputPreview()
}
