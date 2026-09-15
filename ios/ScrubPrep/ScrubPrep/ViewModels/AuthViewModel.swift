import Combine
import Foundation
import ParseSwift

/// The single source of truth for whether the app shows `SignInView` or `RootTabView`
/// (see `ScrubPrepApp`), and the view model backing `SignInView` itself — one class
/// covers both since its state (currentUser, isLoading, errorMessage) is exactly what
/// both need. Auth always talks to the real Parse backend regardless of
/// `AppConfig.useMockData` — that flag exists to avoid OpenAI costs during UI dev, not
/// to mock sign-in.
@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    /// Set right after a successful email/password signup (not Apple — there's no
    /// password to recover on an Apple account, and we don't capture an email for one
    /// either) — the root view shows a one-time "check your inbox" alert on top of the
    /// transition into RootTabView, then clears this.
    @Published var showAccountCreatedAlert = false

    /// ParseSwift restores a logged-in user from the Keychain synchronously at launch —
    /// no network call needed to know whether someone's already signed in.
    init() {
        currentUser = User.current
    }

    func signInWithApple(userIdentifier: String, identityToken: Data) async {
        isLoading = true
        errorMessage = nil
        do {
            currentUser = try await User.apple.login(user: userIdentifier, identityToken: identityToken)
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
        isLoading = false
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            var newUser = User()
            newUser.username = email
            newUser.email = email
            newUser.password = password
            currentUser = try await newUser.signup()
            showAccountCreatedAlert = true
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
        isLoading = false
    }

    func logIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            currentUser = try await User.login(username: email, password: password)
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
        isLoading = false
    }

    /// Clears local state even if the server-side logout call fails (e.g. offline) —
    /// there's nothing useful to show the student for a sign-out failure, and staying
    /// "stuck" signed in because of a network blip would be worse.
    func logOut() async {
        try? await User.logout()
        currentUser = nil
    }

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await User.passwordReset(email: email)
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
        isLoading = false
    }

    private func friendlyMessage(for error: Error) -> String {
        guard let parseError = error as? ParseError else {
            return "Check your connection and try again."
        }
        switch parseError.code {
        case .usernameTaken, .userEmailTaken:
            return "That email is already in use. Try signing in instead."
        case .objectNotFound:
            return "That email or password is incorrect."
        case .connectionFailed:
            return "Check your connection and try again."
        default:
            return "Something went wrong. Please try again."
        }
    }
}
