import SwiftUI

/// The specialty filter row shown above the Home screen heading. Tapping a specialty
/// narrows the case-entry card's quick-pick chips to that specialty; tapping the selected
/// one again clears the filter.
struct SpecialtyRow: View {
    let specialties: [Specialty]
    let selectedSpecialty: Specialty?
    let onSelect: (Specialty) -> Void

    var body: some View {
        ScrollViewReader { proxy in
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
                        .id(specialty.id)
                    }
                }
            }
            // Reveals the selected specialty (e.g. restored from a previous launch, so it
            // wouldn't otherwise be scrolled into view) toward the right side of the visible
            // strip rather than flush against the edge. A no-op (no visible animation) if
            // it's already sitting there.
            .onAppear { scrollToSelected(using: proxy) }
            .onChange(of: selectedSpecialty) { _, _ in scrollToSelected(using: proxy) }
        }
    }

    private func scrollToSelected(using proxy: ScrollViewProxy) {
        guard let selectedSpecialty else { return }
        withAnimation {
            proxy.scrollTo(selectedSpecialty.id, anchor: UnitPoint(x: 0.85, y: 0.5))
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
