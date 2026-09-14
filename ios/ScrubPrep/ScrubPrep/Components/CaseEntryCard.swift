import SwiftUI

/// The dominant "What are you scrubbing on?" card on the Home screen (spec §3).
struct CaseEntryCard: View {
    @Binding var caseDescription: String
    let exampleChips: [CaseType]
    let selectedSpecialty: Specialty?
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    private var isSpecialtySelected: Bool { selectedSpecialty != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What are you scrubbing on?")
                .font(.title3.weight(.semibold))

            if !exampleChips.isEmpty {
                Text("Example cases — tap to use as-is, add to it, or create your own")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(exampleChips) { chip in
                            Button {
                                caseDescription = chip.fullName
                            } label: {
                                Text(chip.name)
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

            // Shown above the text box (rather than below) so it explains what to enter
            // before the student starts typing. Specialty-specific, and only shown once a
            // specialty is selected — no example (generic or otherwise) on a fresh launch.
            if let selectedSpecialty {
                Text("e.g. \u{201C}\(selectedSpecialty.displayedExampleCaseDescription)\u{201D}")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ZStack(alignment: .topLeading) {
                if caseDescription.isEmpty {
                    Text(isSpecialtySelected ? "Enter an operation or case" : "Select a specialty above first")
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                TextEditor(text: $caseDescription)
                    .frame(minHeight: 70)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .disabled(!isSpecialtySelected)
            }
            .padding(8)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(isSpecialtySelected ? 1 : 0.6)

            // Reads as helpful guidance, not a second heading — secondary color and a
            // medium (not bold) weight keep it clearly subordinate to the card title.
            Text("Include important context, such as recurrent disease or redo surgery.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            // Routine privacy guidance, not an error — no warning color.
            Label {
                Text("Don't include patient-identifying information.")
            } icon: {
                Image(systemName: "lock.shield")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

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
            .disabled(!isSpecialtySelected || caseDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    let generalSurgery = Specialty(id: "sp1", name: "General Surgery")
    CaseEntryCard(
        caseDescription: .constant(""),
        exampleChips: [
            CaseType(name: "Lap Chole", fullName: "Laparoscopic Cholecystectomy", specialty: generalSurgery, featured: true),
            CaseType(name: "Appendectomy", fullName: "Appendectomy", specialty: generalSurgery, featured: true),
            CaseType(name: "Inguinal Hernia", fullName: "Inguinal Hernia Repair", specialty: generalSurgery, featured: true),
            CaseType(name: "Colectomy", fullName: "Colectomy", specialty: generalSurgery, featured: true),
        ],
        selectedSpecialty: generalSurgery,
        onSubmit: {}
    )
    .padding()
}
