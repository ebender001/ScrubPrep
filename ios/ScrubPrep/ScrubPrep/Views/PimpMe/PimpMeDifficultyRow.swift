import SwiftUI

/// One row in the Pimp Me difficulty picker — locked with a checkmark once completed
/// (tapping reviews its saved transcript instead of restarting), otherwise selectable.
struct PimpMeDifficultyRow: View {
    let level: PimpDifficulty
    let isCompleted: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.displayName)
                        .font(.subheadline.weight(.semibold))
                    if isCompleted {
                        Text("Completed — tap to review")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text(level.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if isCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
            .background(rowBackground, in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var rowBackground: Color {
        if isCompleted { return Color.green.opacity(0.12) }
        if isSelected { return Color.accentColor.opacity(0.12) }
        return Color(.secondarySystemBackground)
    }
}

#Preview {
    VStack {
        PimpMeDifficultyRow(level: .easy, isCompleted: true, isSelected: false, onSelect: {})
        PimpMeDifficultyRow(level: .typical, isCompleted: false, isSelected: true, onSelect: {})
        PimpMeDifficultyRow(level: .tough, isCompleted: false, isSelected: false, onSelect: {})
    }
    .padding()
}
