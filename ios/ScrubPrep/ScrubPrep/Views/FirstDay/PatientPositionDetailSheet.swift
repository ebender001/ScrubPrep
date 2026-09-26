import SwiftUI

/// The bottom sheet shown when tapping a position — its description, typical uses,
/// pressure points and nerve risks, physiologic effects, how the student can help, and
/// questions you might be asked.
struct PatientPositionDetailSheet: View {
    let position: PatientPosition
    @State private var detent: PresentationDetent

    init(position: PatientPosition, initialDetent: PresentationDetent) {
        self.position = position
        self._detent = State(initialValue: initialDetent)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(position.name)
                        .font(.title3.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                    if let alternateNames = position.alternateNames {
                        Text(alternateNames)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(position.diagrams) { diagram in
                    VStack(alignment: .leading, spacing: 6) {
                        if let caption = diagram.caption {
                            Text(caption)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        // Template-rendered line art, so it follows the text color in
                        // light and dark mode.
                        Image(diagram.assetName)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 16))
                            .accessibilityLabel(
                                "\(diagram.caption.map { "\($0) diagram" } ?? "Diagram") of the \(position.name) position"
                            )
                    }
                }

                Text(position.description)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)

                SectionCard(title: "Commonly used for", systemImage: "list.bullet.clipboard", items: position.commonlyUsedFor)
                SectionCard(
                    title: "Pressure points and nerve risks",
                    systemImage: "exclamationmark.triangle",
                    items: position.pressurePointsAndNerves
                )
                if !position.physiologicEffects.isEmpty {
                    SectionCard(title: "Physiologic effects", systemImage: "lungs", items: position.physiologicEffects)
                }
                SectionCard(title: "How you can help", systemImage: "hand.raised", items: position.howYouCanHelp)

                if !position.questions.isEmpty {
                    PrepLikelyQuestionsCard(title: "What you might be asked", questions: position.questions)
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
    Text("Positioning")
        .sheet(isPresented: .constant(true)) {
            PatientPositionDetailSheet(position: patientPositions[3], initialDetent: .large)
        }
}
