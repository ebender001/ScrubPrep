import SwiftUI

/// The label for a tappable Settings row — an icon and title, plus an optional
/// secondary line, a trailing arrow for links that leave the app, or a spinner while
/// the row's action is running. The row itself (a Button or Link inside a List) is the
/// full-width tap target.
struct SettingsRowLabel: View {
    let title: String
    let systemImage: String
    var subtitle: String?
    var isExternal = false
    var isInProgress = false

    init(
        _ title: String,
        systemImage: String,
        subtitle: String? = nil,
        isExternal: Bool = false,
        isInProgress: Bool = false
    ) {
        self.title = title
        self.systemImage = systemImage
        self.subtitle = subtitle
        self.isExternal = isExternal
        self.isInProgress = isInProgress
    }

    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: systemImage)
            }
            Spacer(minLength: 8)
            if isInProgress {
                ProgressView()
            } else if isExternal {
                Image(systemName: "arrow.up.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    List {
        Button {} label: { SettingsRowLabel("Restore Purchases", systemImage: "arrow.clockwise") }
        Button {} label: { SettingsRowLabel("Restoring", systemImage: "arrow.clockwise", isInProgress: true) }
        Link(destination: URL(string: "https://example.com")!) {
            SettingsRowLabel("Email Support", systemImage: "envelope", subtitle: "support@example.com", isExternal: true)
        }
    }
}
