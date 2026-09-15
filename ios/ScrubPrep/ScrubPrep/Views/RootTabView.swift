import SwiftData
import SwiftUI

/// Bottom tab bar: Home | Cases | Learn | About (spec §3).
struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            HomeView(historyStore: CaseHistoryStore(modelContext: modelContext))
                .tabItem { Label("Home", systemImage: "house.fill") }

            CasesListView()
                .tabItem { Label("Cases", systemImage: "list.bullet.clipboard") }

            LearnView()
                .tabItem { Label("Learn", systemImage: "book.fill") }

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle.fill") }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: ScrubCase.self, PimpMeSession.self, configurations: .init(isStoredInMemoryOnly: true))
    RootTabView()
        .modelContainer(container)
}
