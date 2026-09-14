import SwiftUI

/// The Learn tab. For v1 this primarily leads to First Day content (spec §3); more
/// learning content can be added here later without changing the tab structure.
struct LearnView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    FirstDayView()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("First Day?")
                                .font(.subheadline.weight(.semibold))
                            Text("Rounds, scrubbing, OR etiquette, and presentations.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.blue)
                    }
                }

                NavigationLink {
                    InstrumentsView()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Instruments 101")
                                .font(.subheadline.weight(.semibold))
                            Text("Common instruments and what they're used for.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "scissors")
                            .foregroundStyle(.teal)
                    }
                }

                NavigationLink {
                    AbbreviationsView()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Abbreviations")
                                .font(.subheadline.weight(.semibold))
                            Text("Common OR and surgical shorthand.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "character.book.closed.fill")
                            .foregroundStyle(.indigo)
                    }
                }
            }
            .navigationTitle("Learn")
        }
    }
}

#Preview {
    LearnView()
}
