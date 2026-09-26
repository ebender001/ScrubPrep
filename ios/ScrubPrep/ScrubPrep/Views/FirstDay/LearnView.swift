import SwiftUI

/// The Learn tab. For v1 this primarily leads to First Day content (spec §3); more
/// learning content can be added here later without changing the tab structure.
struct LearnView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Getting Started") {
                    NavigationLink {
                        FirstDayView()
                    } label: {
                        LearnRow(
                            title: "First day in the OR",
                            subtitle: "Rounds, scrubbing, OR etiquette, and presentations.",
                            systemImage: "sparkles"
                        )
                    }
                }

                Section("Reference") {
                    NavigationLink {
                        InstrumentsView()
                    } label: {
                        LearnRow(
                            title: "Instruments 101",
                            subtitle: "Common instruments and what they're used for.",
                            systemImage: "scissors"
                        )
                    }

                    NavigationLink {
                        AbbreviationsView()
                    } label: {
                        LearnRow(
                            title: "Abbreviations",
                            subtitle: "Common OR and surgical shorthand.",
                            systemImage: "character.book.closed.fill"
                        )
                    }

                    NavigationLink {
                        EnergyDevicesView()
                    } label: {
                        LearnRow(
                            title: "Energy devices",
                            subtitle: "Bovie, bipolar, vessel sealers, and what each is for.",
                            systemImage: "bolt"
                        )
                    }
                }
            }
            .navigationTitle("Learn")
        }
    }
}

/// One Learn tab row: an accent-tinted icon beside a title and one-line description.
private struct LearnRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accentColor)
        }
    }
}

#Preview {
    LearnView()
}
