import SwiftUI

/// The dominant "What are you scrubbing on?" card on the Home screen (spec §3).
struct CaseEntryCard: View {
    @Binding var caseDescription: String
    let exampleChips: [String]
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What are you scrubbing on?")
                .font(.title3.weight(.semibold))

            ZStack(alignment: .topLeading) {
                if caseDescription.isEmpty {
                    Text("Enter an operation or case")
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                TextEditor(text: $caseDescription)
                    .frame(minHeight: 70)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
            }
            .padding(8)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("e.g. \u{201C}Lap chole for symptomatic gallstones\u{201D}")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Do not enter patient names, dates of birth, medical record numbers, or other identifying information.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if !exampleChips.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(exampleChips, id: \.self) { chip in
                            Button {
                                caseDescription = chip
                            } label: {
                                Text(chip)
                                    .font(.footnote.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(Color.accentColor.opacity(0.12), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Button(action: {
                isFocused = false
                onSubmit()
            }) {
                Text("Prepare Me")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .disabled(caseDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    CaseEntryCard(caseDescription: .constant(""), exampleChips: ["Lap Chole", "Appendectomy", "Inguinal Hernia", "Colectomy"], onSubmit: {})
        .padding()
}
