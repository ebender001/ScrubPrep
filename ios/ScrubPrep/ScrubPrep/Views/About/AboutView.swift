import SwiftUI

/// About screen (spec §1, §15) — informational, account sign-out, and subscription
/// management.
struct AboutView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Scrub Prep")
                            .font(.title2.weight(.bold))
                        Text("Your AI companion for the surgery clerkship.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Account")
                            .font(.headline)
                        Text(accountDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Sign Out", role: .destructive) {
                            showSignOutConfirmation = true
                        }
                        .font(.subheadline.weight(.medium))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: .rect(cornerRadius: 16))

                    SubscriptionCard()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Medical Disclaimer")
                            .font(.headline)
                        Text("Scrub Prep is an educational tool for medical students and is not intended to provide patient-specific medical advice, diagnosis, or treatment recommendations. Clinical decisions should be made under the supervision of the student's clinical team.")
                            .font(.subheadline)
                        Link("Report an AI Concern", destination: URL(string: "mailto:support@benderapps.dev?subject=Report%20AI%20concerns")!)
                            .font(.subheadline.weight(.medium))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: .rect(cornerRadius: 16))

                    HStack(alignment: .top, spacing: 12) {
                        Image("creator-headshot")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .accessibilityLabel("Portrait of Dr. Edward Bender, retired cardiothoracic surgeon and creator of Scrub Prep")

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Creator")
                                .font(.headline)
                            Text("Scrub Prep was created by Edward Bender, MD, a retired cardiothoracic surgeon and former Clinical Professor of Cardiothoracic Surgery at Stanford University.")
                                .font(.subheadline)
                            Text("Scrub Prep is an independent educational application and is not affiliated with or endorsed by Stanford University.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: .rect(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contact")
                            .font(.headline)
                        Text("Questions, feedback, or something not working? Reach out anytime.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Link("support@benderapps.dev", destination: URL(string: "mailto:support@benderapps.dev?subject=Scrub%20Prep")!)
                            .font(.subheadline.weight(.medium))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: .rect(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("About")
            .confirmationDialog(
                "Sign out of Scrub Prep?",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    Task { await authViewModel.logOut() }
                }
                Button("Cancel", role: .cancel) {}
            }
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
    AboutView()
        .environment(AuthViewModel())
        .environment(SubscriptionManager())
}
