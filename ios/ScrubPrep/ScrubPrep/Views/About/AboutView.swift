import SwiftUI

/// About screen (spec §1, §15) — informational, account sign-out, and subscription
/// management.
struct AboutView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var showPaywall = false
    @State private var isRestoring = false
    @State private var restoreResultMessage: String?

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
                            Task { await authViewModel.logOut() }
                        }
                        .font(.subheadline.weight(.medium))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    subscriptionCard

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Medical Disclaimer")
                            .font(.headline)
                        Text("Scrub Prep is an educational tool for medical students and is not intended to provide patient-specific medical advice, diagnosis, or treatment recommendations. Clinical decisions should be made under the supervision of the student's clinical team.")
                            .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Creator")
                            .font(.headline)
                        Text("Scrub Prep was created by Edward Bender, MD, a retired cardiothoracic surgeon and former Clinical Professor of Cardiothoracic Surgery at Stanford University.")
                            .font(.subheadline)
                        Text("Scrub Prep is an independent educational application and is not affiliated with or endorsed by Stanford University.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

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
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding()
            }
            .navigationTitle("About")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("Restore Purchases", isPresented: restoreResultBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(restoreResultMessage ?? "")
            }
        }
    }

    private var restoreResultBinding: Binding<Bool> {
        Binding(
            get: { restoreResultMessage != nil },
            set: { if !$0 { restoreResultMessage = nil } }
        )
    }

    private var accountDescription: String {
        if let email = authViewModel.currentUser?.email, !email.isEmpty {
            return "Signed in as \(email)."
        }
        return "Signed in with Apple."
    }

    private var subscriptionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Subscription")
                .font(.headline)
            Text(subscriptionStatusLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if subscriptionManager.hasActiveSubscription {
                Link("Manage Subscription", destination: Self.manageSubscriptionsURL)
                    .font(.subheadline.weight(.medium))
            } else {
                Button("Subscribe") {
                    showPaywall = true
                }
                .font(.subheadline.weight(.medium))
            }

            Button {
                restorePurchases()
            } label: {
                if isRestoring {
                    ProgressView()
                } else {
                    Text("Restore Purchases")
                }
            }
            .font(.subheadline.weight(.medium))
            .disabled(isRestoring)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // Never describes a canceled-but-still-valid subscription as "expired" — a canceled
    // subscription (autoRenewStatus false) that's still within its paid period reads as
    // "Active until <date>", same as an auto-renewing one reads as "Renews <date>".
    private var subscriptionStatusLine: String {
        guard let subscription = subscriptionManager.accessStatus?.subscription else {
            return "No active subscription."
        }
        let dateText = { (date: Date?) in
            date?.formatted(date: .abbreviated, time: .omitted) ?? "soon"
        }
        switch subscription.status {
        case "active":
            if subscription.autoRenewStatus == true {
                return "Renews \(dateText(subscription.expiresAt))."
            }
            return "Active until \(dateText(subscription.accessEndsAt)) (auto-renew is off)."
        case "grace_period":
            return "There's a problem with your payment method. Access continues until \(dateText(subscription.accessEndsAt)) while Apple retries."
        case "billing_retry":
            return "There's a problem with your payment method. Please update it to keep your subscription active."
        case "expired":
            return "Your subscription has expired."
        case "revoked":
            return "Your subscription was refunded."
        default:
            return "No active subscription."
        }
    }

    private func restorePurchases() {
        isRestoring = true
        Task {
            do {
                try await subscriptionManager.restore()
                isRestoring = false
                restoreResultMessage = subscriptionManager.hasActiveSubscription
                    ? "Your subscription has been restored."
                    : "No active subscription was found for this Apple ID."
            } catch {
                isRestoring = false
                restoreResultMessage = "Couldn't restore purchases. Check your connection and try again."
            }
        }
    }

    // Opens Apple's own hosted subscription-management page externally (App Store app,
    // falling back to Safari) rather than using StoreKit 2's in-app
    // `AppStore.showManageSubscriptions(in:)` sheet — that API has known real-world
    // reports of occasionally presenting a blank sheet with a spinner that never loads
    // (particularly right after a fresh purchase, or on certain iOS versions). This URL
    // can't fail that way: it just hands off to a page Apple renders itself.
    private static let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!
}

#Preview {
    AboutView()
        .environmentObject(AuthViewModel())
        .environmentObject(SubscriptionManager())
}
