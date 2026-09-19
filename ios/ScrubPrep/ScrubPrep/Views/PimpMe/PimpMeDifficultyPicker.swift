import SwiftUI

/// The Pimp Me entry screen — pick a difficulty (or tap an already-completed one to
/// review its transcript) and start.
struct PimpMeDifficultyPicker: View {
    let prepTitle: String
    let completedDifficulties: Set<PimpDifficulty>
    let selectedDifficulty: PimpDifficulty
    let allDifficultiesCompleted: Bool
    let onSelectDifficulty: (PimpDifficulty) -> Void
    let onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Test me before I scrub.")
                    .font(.title3.weight(.semibold))
                Text("Interactive questions tailored to \(prepTitle). Pick how tough you want it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 10) {
                    ForEach(PimpDifficulty.allCases) { level in
                        let isCompleted = completedDifficulties.contains(level)
                        PimpMeDifficultyRow(
                            level: level,
                            isCompleted: isCompleted,
                            isSelected: !isCompleted && selectedDifficulty == level,
                            onSelect: { onSelectDifficulty(level) }
                        )
                    }
                }

                if allDifficultiesCompleted {
                    Text("You've completed every difficulty for this case. Tap any level above to review it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Button(action: onStart) {
                        Text("Start")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }
}

#Preview {
    PimpMeDifficultyPicker(
        prepTitle: "Laparoscopic Cholecystectomy",
        completedDifficulties: [.easy],
        selectedDifficulty: .typical,
        allDifficultiesCompleted: false,
        onSelectDifficulty: { _ in },
        onStart: {}
    )
}
