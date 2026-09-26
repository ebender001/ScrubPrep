import SwiftUI

/// The specialty filter shown as a drop-down in the Home screen's trailing toolbar slot.
/// Picking a specialty narrows the case-entry card's quick-pick chips to that specialty;
/// picking the selected one again clears the filter.
struct SpecialtyMenu: View {
    let specialties: [Specialty]
    let selectedSpecialty: Specialty?
    let onSelect: (Specialty) -> Void

    private var sortedSpecialties: [Specialty] {
        specialties.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        Menu {
            ForEach(sortedSpecialties) { specialty in
                Button {
                    onSelect(specialty)
                } label: {
                    if specialty == selectedSpecialty {
                        Label(specialty.name, systemImage: "checkmark")
                    } else {
                        Text(specialty.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedSpecialty?.name ?? "Specialty")
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .font(.subheadline.weight(.medium))
        }
        .accessibilityLabel("Specialty")
        .accessibilityValue(selectedSpecialty?.name ?? "None")
    }
}

#Preview {
    NavigationStack {
        Text("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SpecialtyMenu(
                        specialties: [
                            Specialty(id: "1", name: "General Surgery"),
                            Specialty(id: "2", name: "Cardiac Surgery"),
                            Specialty(id: "3", name: "ENT"),
                        ],
                        selectedSpecialty: Specialty(id: "1", name: "General Surgery"),
                        onSelect: { _ in }
                    )
                }
            }
    }
}
