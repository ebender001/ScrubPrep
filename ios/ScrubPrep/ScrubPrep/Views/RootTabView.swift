import SwiftData
import SwiftUI

/// Bottom tab bar: Home | Cases | Learn | Profile (spec §3).
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

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: ScrubCase.self, configurations: .init(isStoredInMemoryOnly: true))
    RootTabView()
        .modelContainer(container)
}
