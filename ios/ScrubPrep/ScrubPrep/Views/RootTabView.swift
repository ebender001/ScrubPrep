import SwiftUI

private enum RootTab: Hashable {
    case home, cases, learn, settings
}

/// Bottom tab bar: Home | Cases | Learn | Settings (spec §3).
struct RootTabView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: RootTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: RootTab.home) {
                HomeView()
            }

            Tab("Cases", systemImage: "list.bullet.clipboard", value: RootTab.cases) {
                CasesListView()
            }

            Tab("Learn", systemImage: "book.fill", value: RootTab.learn) {
                LearnView()
            }

            Tab("Settings", systemImage: "gearshape.fill", value: RootTab.settings) {
                SettingsView()
            }
        }
        // Only ever shown once signed in, so this is exactly "refresh on sign-in and on
        // every subsequent foreground" — the two moments StoreKit's own entitlement state
        // most needs re-checking.
        .task {
            await subscriptionManager.refreshEntitlements()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await subscriptionManager.refreshEntitlements() }
            }
        }
    }
}

#Preview {
    RootTabView()
        .environment(AuthViewModel())
        .environment(SubscriptionManager())
}
