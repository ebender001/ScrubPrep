import SwiftUI

/// The specialty filter row shown above the Home screen heading. Tapping a specialty
/// narrows the case-entry card's quick-pick chips to that specialty; tapping the selected
/// one again clears the filter.
struct SpecialtyRow: View {
    let specialties: [Specialty]
    let selectedSpecialty: Specialty?
    let onSelect: (Specialty) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(specialties) { specialty in
                    let isSelected = specialty == selectedSpecialty
                    Button {
                        onSelect(specialty)
                    } label: {
                        Text(specialty.name)
                            .font(.footnote.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                            .background(
                                isSelected ? Color.accentColor : Color.accentColor.opacity(0.12),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    SpecialtyRow(
        specialties: [
            Specialty(id: "1", name: "General Surgery"),
            Specialty(id: "2", name: "Cardiac Surgery"),
            Specialty(id: "3", name: "ENT"),
        ],
        selectedSpecialty: Specialty(id: "1", name: "General Surgery"),
        onSelect: { _ in }
    )
    .padding()
}
