import SwiftUI

/// Bottom tab bar: Home | Cases | Learn | About (spec §3).
struct RootTabView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.scenePhase) private var scenePhase

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
        // Only ever shown once signed in, so this is exactly "refresh on sign-in and on
        // every subsequent foreground" — the two moments StoreKit/backend state most
        // needs re-syncing (spec: "App relaunch and foreground refresh").
        .task {
            await subscriptionManager.refreshAccessStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await subscriptionManager.refreshAccessStatus() }
            }
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(SubscriptionManager())
}
