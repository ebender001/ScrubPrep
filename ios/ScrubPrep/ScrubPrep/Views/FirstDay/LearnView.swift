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
            }
            .navigationTitle("Learn")
        }
    }
}

#Preview {
    LearnView()
}
