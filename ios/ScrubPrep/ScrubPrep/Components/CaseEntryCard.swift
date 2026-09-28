import SwiftUI

/// The dominant "What are you scrubbing on?" card on the Home screen (spec §3).
struct CaseEntryCard: View {
    @Binding var caseDescription: String
    let exampleChips: [CaseType]
    let selectedSpecialty: Specialty?
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    private var isSpecialtySelected: Bool { selectedSpecialty != nil }

    /// Doubles as the instructions and the specialty-specific example, so the student
    /// sees what to enter right where they type. No example (generic or otherwise)
    /// before a specialty is selected.
    private var placeholder: String {
        guard let selectedSpecialty else { return "Select a specialty first" }
        let example = selectedSpecialty.displayedExampleCaseDescription
        return exampleChips.isEmpty
            ? "e.g. \(example)"
            : "Type a case or tap one below, e.g. \(example)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What are you scrubbing on?")
                .font(.title3.weight(.semibold))

            TextField(
                placeholder,
                text: $caseDescription,
                axis: .vertical
            )
            .lineLimit(3...)
            .focused($isFocused)
            .disabled(!isSpecialtySelected)
            .padding(10)
            .padding(.trailing, caseDescription.isEmpty ? 0 : 24)
            // Solid fill plus a border so the field reads as tappable against the card's
            // translucent material.
            .background(Color(.systemBackground), in: .rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isFocused ? Color.accentColor : Color(.separator), lineWidth: 1)
            }
            .opacity(isSpecialtySelected ? 1 : 0.6)
            .overlay(alignment: .topTrailing) {
                if !caseDescription.isEmpty {
                    Button {
                        caseDescription = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(10)
                    .accessibilityLabel("Clear")
                }
            }

            if !exampleChips.isEmpty {
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

            // Routine privacy guidance, not an error — no warning color.
            Label {
                Text("No patient-identifying information")
            } icon: {
                Image(systemName: "lock.shield")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: .rect(cornerRadius: 20))
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
