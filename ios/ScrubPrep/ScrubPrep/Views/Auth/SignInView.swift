import AuthenticationServices
import SwiftUI

/// Shown whenever `authViewModel.currentUser == nil` (see `ScrubPrepApp`) — sign-in is
/// mandatory, since Cases and Pimp Me sessions live on the backend as the single source
/// of truth, not the device.
struct SignInView: View {
    private enum Mode {
        case signUp
        case logIn
    }

    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var mode: Mode = .logIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var infoMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Scrub Prep")
                        .font(.largeTitle.weight(.bold))
                    Text("Your AI companion for the surgery clerkship.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email]
                } onCompletion: { result in
                    handleAppleCompletion(result)
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)
                .disabled(authViewModel.isLoading)

                HStack {
                    Rectangle().frame(height: 1).foregroundStyle(.tertiary)
                    Text("or").font(.caption).foregroundStyle(.secondary)
                    Rectangle().frame(height: 1).foregroundStyle(.tertiary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    SecureField("Password", text: $password)
                        .textContentType(mode == .signUp ? .newPassword : .password)
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    if mode == .signUp {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        if !confirmPassword.isEmpty && confirmPassword != password {
                            Text("Passwords don't match.")
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        } else {
                            Text(mode == .signUp ? "Create Account" : "Sign In")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(authViewModel.isLoading || !isFormValid)

                    if let infoMessage {
                        Text(infoMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Button(mode == .signUp ? "Already have an account? Sign in" : "New here? Create an account") {
                            mode = mode == .signUp ? .logIn : .signUp
                            infoMessage = nil
                            confirmPassword = ""
                        }
                        .font(.footnote)

                        Spacer()

                        if mode == .logIn {
                            Button("Forgot password?") {
                                Task { await sendPasswordReset() }
                            }
                            .font(.footnote)
                            .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
            .padding()
        }
        .alert("Couldn't sign in", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authViewModel.errorMessage ?? "")
        }
    }

    private var isFormValid: Bool {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !password.isEmpty else { return false }
        guard mode == .signUp else { return true }
        return password == confirmPassword
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { authViewModel.errorMessage != nil },
            set: { if !$0 { authViewModel.errorMessage = nil } }
        )
    }

    private func submit() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        infoMessage = nil
        if mode == .signUp {
            await authViewModel.signUp(email: trimmedEmail, password: password)
        } else {
            await authViewModel.logIn(email: trimmedEmail, password: password)
        }
    }

    private func sendPasswordReset() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        await authViewModel.resetPassword(email: trimmedEmail)
        if authViewModel.errorMessage == nil {
            infoMessage = "If an account exists for \(trimmedEmail), a reset link is on its way."
        }
    }

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken else {
                authViewModel.errorMessage = "Sign in with Apple failed. Please try again."
                return
            }
            Task {
                await authViewModel.signInWithApple(userIdentifier: credential.user, identityToken: tokenData, email: credential.email)
            }
        case .failure(let error):
            // Don't surface the user simply dismissing the Apple sheet as an error.
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            authViewModel.errorMessage = "Sign in with Apple failed. Please try again."
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthViewModel())
}
