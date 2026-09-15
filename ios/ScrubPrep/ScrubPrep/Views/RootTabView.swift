import SwiftUI

/// Bottom tab bar: Home | Cases | Learn | About (spec §3).
struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
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
    RootTabView()
        .environmentObject(AuthViewModel())
}
