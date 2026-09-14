import SwiftUI

/// Bottom tab bar: Home | Cases | Learn | Profile (spec §3).
struct RootTabView: View {
    @EnvironmentObject private var historyStore: CaseHistoryStore

    var body: some View {
        TabView {
            HomeView(historyStore: historyStore)
                .tabItem { Label("Home", systemImage: "house.fill") }

            CasesListView(historyStore: historyStore)
                .tabItem { Label("Cases", systemImage: "list.bullet.clipboard") }

            LearnView()
                .tabItem { Label("Learn", systemImage: "book.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(CaseHistoryStore())
}
