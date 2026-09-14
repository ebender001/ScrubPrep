import Foundation

/// Central place for backend configuration. Nothing here is a secret in the way an
/// OpenAI key is — the Parse Client Key is designed to ship inside client apps and is
/// scoped by the server's Class-Level Permissions, unlike the Master Key (which must
/// only ever live server-side, see backend/README.md).
enum AppConfig {
    static let parseApplicationId = "8wtDjVoWgS9tKzB9DFwsXpnvOsJsyZuAl0RR6J6c"

    /// TODO(Phase 2): replace with the real Client Key from the Back4App dashboard
    /// (App Settings -> Security & Keys -> Client Key). Safe to leave as a placeholder
    /// while `useMockData` is true.
    static let parseClientKey = "REPLACE_WITH_CLIENT_KEY"

    static let parseServerURL = URL(string: "https://parseapi.back4app.com/")!

    /// When true, view models use bundled mock data (see Services/MockScrubPrepService.swift)
    /// instead of calling the deployed Cloud Functions. Flip to false once `parseClientKey`
    /// is filled in to test against the real backend (Phase 2).
    static let useMockData = true
}
