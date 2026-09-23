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

    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.colorScheme) private var colorScheme

    // Defaults to account creation: sessions persist until an explicit sign-out, so most
    // students only ever type credentials here once, to sign up.
    @State private var mode: Mode = .signUp
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var infoMessage: String?
    @State private var isShowingError = false
    @Namespace private var modeSelectionNamespace

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

                // `.continue` rather than `.signIn`: the same button creates an account for a
                // first-time user, so "Sign in" would wrongly suggest one must already exist.
                SignInWithAppleButton(.continue) { request in
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
                    // A segmented control rather than a footnote link, so switching to
                    // Sign In is obvious for a returning student on a new device.
                    // Custom rather than `.pickerStyle(.segmented)`, which can't take the
                    // accent color for its selected segment.
                    HStack(spacing: 0) {
                        modeSegment("Create Account", mode: .signUp)
                        modeSegment("Sign In", mode: .logIn)
                    }
                    .padding(3)
                    .background(Color(.secondarySystemBackground), in: .capsule)
                    .padding(.bottom, 4)

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 12))

                    SecureField("Password", text: $password)
                        .textContentType(mode == .signUp ? .newPassword : .password)
                        .padding()
                        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 12))

                    if mode == .signUp {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 12))

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

                    if mode == .logIn {
                        HStack {
                            Spacer()
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
        .alert(mode == .signUp ? "Couldn't create account" : "Couldn't sign in", isPresented: $isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authViewModel.errorMessage ?? "")
        }
        .onAppear {
            // Arriving with an error already set means an existing account was just
            // bounced here (e.g. AuthViewModel's session-expired handling) — they need to
            // sign back in, not create a new account. The alert has to be raised here too:
            // the onChange below only fires on later changes, never for a message that was
            // already set before this view appeared.
            if authViewModel.errorMessage != nil {
                mode = .logIn
                isShowingError = true
            }
        }
        .onChange(of: mode) {
            infoMessage = nil
            confirmPassword = ""
        }
        .onChange(of: authViewModel.errorMessage) { _, newValue in
            isShowingError = newValue != nil
        }
    }

    private func modeSegment(_ title: String, mode segmentMode: Mode) -> some View {
        let isSelected = mode == segmentMode
        return Button {
            withAnimation(.snappy(duration: 0.25)) { mode = segmentMode }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(.tint)
                            .matchedGeometryEffect(id: "modeSelection", in: modeSelectionNamespace)
                    }
                }
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var isFormValid: Bool {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !password.isEmpty else { return false }
        guard mode == .signUp else { return true }
        return password == confirmPassword
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
        .environment(AuthViewModel())
}
