import SwiftUI

/// The bottom sheet shown when tapping an incision — its diagram, where it runs, typical
/// uses, anatomy and structures at risk, tradeoffs, and questions you might be asked.
struct IncisionDetailSheet: View {
    let incision: Incision
    @State private var detent: PresentationDetent

    init(incision: Incision, initialDetent: PresentationDetent) {
        self.incision = incision
        self._detent = State(initialValue: initialDetent)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(incision.name)
                        .font(.title3.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                    if let alternateNames = incision.alternateNames {
                        Text(alternateNames)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(incision.diagrams) { diagram in
                    LearnDiagramView(diagram: diagram, subject: "the \(incision.name)")
                }

                Text(incision.description)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)

                SectionCard(title: "Commonly used for", systemImage: "list.bullet.clipboard", items: incision.commonlyUsedFor)
                SectionCard(
                    title: "Anatomy and structures at risk",
                    systemImage: "exclamationmark.triangle",
                    items: incision.anatomy
                )
                SectionCard(title: "Tradeoffs", systemImage: "scalemass", items: incision.tradeoffs)

                if !incision.questions.isEmpty {
                    PrepLikelyQuestionsCard(title: "What you might be asked", questions: incision.questions)
                }
            }
            .padding()
            // Clears the drag indicator, which otherwise crowds the first line.
            .padding(.top, 12)
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        // Opaque — the default translucent sheet at the medium detent lets the list
        // behind it show through the text.
        .presentationBackground(Color(.systemBackground))
    }
}

#Preview {
    Text("Incisions")
        .sheet(isPresented: .constant(true)) {
            IncisionDetailSheet(incision: incisionRegions[2].incisions[5], initialDetent: .large)
        }
}
