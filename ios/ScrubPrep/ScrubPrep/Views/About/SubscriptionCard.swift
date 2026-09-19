import StoreKit
import SwiftUI

/// The Subscription section of the About screen — current plan, subscribe/manage link,
/// and Restore Purchases. Fully self-contained: owns its own paywall sheet and restore
/// alert rather than coordinating that state through its parent.
struct SubscriptionCard: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var showPaywall = false
    @State private var isRestoring = false
    @State private var restoreResultMessage: String?
    @State private var isShowingRestoreResult = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Subscription")
                .font(.headline)
            if let planName = currentPlanName {
                Text(planName)
                    .font(.subheadline.weight(.medium))
            }
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
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Restore Purchases", isPresented: $isShowingRestoreResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreResultMessage ?? "")
        }
        .onChange(of: restoreResultMessage) { _, newValue in
            isShowingRestoreResult = newValue != nil
        }
    }

    // The subscribed product's own StoreKit display name (e.g. "Scrub Prep Pro Monthly")
    // — nil while products haven't loaded yet or there's no active subscription.
    private var currentPlanName: String? {
        guard let productID = subscriptionManager.activeSubscription?.productID else { return nil }
        return subscriptionManager.products.first { $0.id == productID }?.displayName
    }

    // Never describes a canceled-but-still-valid subscription as "expired" — a canceled
    // subscription (willAutoRenew false) that's still within its paid period reads as
    // "Active until <date>", same as an auto-renewing one reads as "Renews <date>". There
    // is no separate "grace period"/"billing retry" display state here: StoreKit's
    // `Transaction.currentEntitlements` already folds an Apple-managed billing grace
    // period into the entitlement itself, so this app only ever sees "active" or "not."
    private var subscriptionStatusLine: String {
        guard let subscription = subscriptionManager.activeSubscription else {
            return "No active subscription."
        }
        let dateText = subscription.expirationDate?.formatted(date: .abbreviated, time: .omitted) ?? "soon"
        if subscription.willAutoRenew {
            return "Renews \(dateText)."
        }
        return "Active until \(dateText) (auto-renew is off)."
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
    SubscriptionCard()
        .environment(SubscriptionManager())
        .padding()
}
