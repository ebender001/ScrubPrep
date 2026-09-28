import SwiftUI

/// Settings tab (spec §1, §15; formerly "About") — account sign-out and deletion,
/// subscription management, and app information.
struct SettingsView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var showSignOutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var isDeletingAccount = false
    @State private var showDeleteAccountError = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scrub Prep")
                            .font(.title2.weight(.bold))
                        Text("Your AI companion for the surgery clerkship.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                }

                Section("Account") {
                    Text(accountDescription)
                        .foregroundStyle(.secondary)
                    Button(role: .destructive) {
                        showSignOutConfirmation = true
                    } label: {
                        SettingsRowLabel("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    Button(role: .destructive) {
                        showDeleteAccountConfirmation = true
                    } label: {
                        SettingsRowLabel("Delete Account", systemImage: "trash", isInProgress: isDeletingAccount)
                    }
                    .disabled(isDeletingAccount)
                }

                SubscriptionSection()

                Section {
                    Text("Scrub Prep is an educational tool for medical students and is not intended to provide patient-specific medical advice, diagnosis, or treatment recommendations. Clinical decisions should be made under the supervision of the student's clinical team.")
                        .font(.subheadline)
                    Link(destination: URL(string: "mailto:support@benderapps.dev?subject=Report%20AI%20concerns")!) {
                        SettingsRowLabel("Report an AI Concern", systemImage: "exclamationmark.bubble", isExternal: true)
                    }
                } header: {
                    Text("Medical Disclaimer")
                }

                Section("Creator") {
                    HStack(alignment: .top, spacing: 12) {
                        Image("creator-headshot")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .accessibilityLabel("Portrait of Dr. Edward Bender, retired cardiothoracic surgeon and creator of Scrub Prep")

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Scrub Prep was created by Edward Bender, MD, a retired cardiothoracic surgeon and former Clinical Professor of Cardiothoracic Surgery at Stanford University.")
                                .font(.subheadline)
                            Text("Scrub Prep is an independent educational application and is not affiliated with or endorsed by Stanford University.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Link(destination: URL(string: "mailto:support@benderapps.dev?subject=Scrub%20Prep")!) {
                        SettingsRowLabel(
                            "Email Support",
                            systemImage: "envelope",
                            subtitle: "support@benderapps.dev",
                            isExternal: true
                        )
                    }
                } header: {
                    Text("Contact")
                } footer: {
                    Text("Questions, feedback, or something not working? Reach out anytime.")
                }

                Section("Legal") {
                    if let termsURL = AppLinks.termsOfUseURL {
                        Link(destination: termsURL) {
                            SettingsRowLabel("Terms of Use", systemImage: "doc.text", isExternal: true)
                        }
                    }
                    if let privacyURL = AppLinks.privacyPolicyURL {
                        Link(destination: privacyURL) {
                            SettingsRowLabel("Privacy Policy", systemImage: "hand.raised", isExternal: true)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .alert("Sign out of Scrub Prep?", isPresented: $showSignOutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    Task { await authViewModel.logOut() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your saved cases and notes stay with your account, so they'll be here when you sign back in.")
            }
            .alert("Delete your account?", isPresented: $showDeleteAccountConfirmation) {
                Button("Delete Account", role: .destructive) {
                    Task { await deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your account, saved cases, and Quiz Me sessions. This can't be undone. Deleting your account doesn't cancel an active subscription — cancel it first from the Subscription section above.")
            }
            .alert("Couldn't Delete Account", isPresented: $showDeleteAccountError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Check your connection and try again. If this keeps happening, contact support@benderapps.dev.")
            }
        }
    }

    private func deleteAccount() async {
        isDeletingAccount = true
        let deleted = await authViewModel.deleteAccount()
        isDeletingAccount = false
        if !deleted {
            showDeleteAccountError = true
        }
    }

    private var accountDescription: String {
        if let email = authViewModel.currentUser?.email, !email.isEmpty {
            return "Signed in as \(email)."
        }
        return "Signed in with Apple."
    }
}

#Preview {
    SettingsView()
        .environment(AuthViewModel())
        .environment(SubscriptionManager())
}
