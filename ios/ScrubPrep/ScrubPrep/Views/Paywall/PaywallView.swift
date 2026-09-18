import StoreKit
import SwiftUI

/// The paywall — shown when `HomeViewModel.resolvePrep` determines (entirely
/// client-side, before any AI request) that a new case needs a subscription, or opened
/// directly from About/Home for someone who wants to subscribe proactively. Never
/// mentions the complimentary case — this screen exists to sell the subscription, not
/// explain the free-case mechanic.
///
/// `onPurchaseCompleted` is called exactly once, right after StoreKit confirms an active
/// entitlement — the presenter (HomeView) uses it to dismiss this sheet and resume
/// whatever case-generation attempt triggered the paywall, exactly once.
struct PaywallView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    var onPurchaseCompleted: () -> Void = {}

    private enum PurchaseState: Equatable {
        case idle
        case purchasing
        case verifying
        case pending
        case restoring
    }

    // Defaults to the better-value plan (see bestValueChip) — leading with, and
    // pre-selecting, the recommended option is standard paywall practice.
    @State private var selectedProductID = SubscriptionManager.quarterlyProductID
    @State private var purchaseState: PurchaseState = .idle
    @State private var errorMessage: String?

    private var isBusy: Bool { purchaseState != .idle }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Prepare for your next case")
                            .font(.title2.weight(.bold))
                        Text("Get access to case preparation, Pimp Me, and Rapid Fire.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if subscriptionManager.isLoadingProducts {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical, 24)
                    } else if let loadError = subscriptionManager.productsLoadError {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(loadError)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button("Try Again") {
                                Task { await subscriptionManager.loadProducts() }
                            }
                            .font(.subheadline.weight(.medium))
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        planOptions

                        if purchaseState == .pending {
                            Label("Waiting for approval — you'll get access once it's confirmed.", systemImage: "clock")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if purchaseState == .verifying {
                            Label("Purchase received — confirming with our server\u{2026}", systemImage: "arrow.triangle.2.circlepath")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }

                        Button {
                            subscribe()
                        } label: {
                            HStack {
                                if purchaseState == .purchasing {
                                    ProgressView()
                                        .tint(.white)
                                }
                                Text("Subscribe")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isBusy || selectedProduct == nil)

                        Text("Payment is charged to your Apple Account at confirmation. Your subscription renews automatically unless canceled at least 24 hours before the current period ends. Manage or cancel in your Apple Account settings.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            restore()
                        } label: {
                            if purchaseState == .restoring {
                                ProgressView()
                            } else {
                                Text("Restore Purchases")
                            }
                        }
                        .font(.subheadline.weight(.medium))
                        .disabled(isBusy)
                        .frame(maxWidth: .infinity)

                        legalLinks
                    }
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Dismiss")
                }
            }
        }
        .task {
            if subscriptionManager.products.isEmpty {
                await subscriptionManager.loadProducts()
            }
        }
        // Falls back to whatever plan actually loaded if the preferred default
        // (quarterly) isn't among the loaded products — e.g. it's still stuck in
        // "Prepare for Submission" in App Store Connect and Apple silently omitted it
        // rather than erroring. Without this, Subscribe stays permanently disabled and
        // nothing appears selected whenever only one plan is available.
        .onChange(of: subscriptionManager.products.map(\.id), initial: true) { _, ids in
            if !ids.contains(selectedProductID), let fallback = sortedProducts.first?.id {
                selectedProductID = fallback
            }
        }
    }

    private var selectedProduct: Product? {
        subscriptionManager.products.first { $0.id == selectedProductID }
    }

    // The better-value plan leads — matches it also being the default selection (above)
    // and carrying the "Best Value" chip (below), rather than an arbitrary shortest-first
    // ordering that would visually disagree with which one is actually recommended.
    private var sortedProducts: [Product] {
        subscriptionManager.products.sorted { lhs, rhs in
            if lhs.id == SubscriptionManager.quarterlyProductID { return true }
            if rhs.id == SubscriptionManager.quarterlyProductID { return false }
            return (lhs.subscription?.subscriptionPeriod.value ?? 0) < (rhs.subscription?.subscriptionPeriod.value ?? 0)
        }
    }

    private var planOptions: some View {
        VStack(spacing: 10) {
            ForEach(sortedProducts) { product in
                planCard(for: product)
            }
        }
    }

    private func planCard(for product: Product) -> some View {
        let isSelected = product.id == selectedProductID
        return Button {
            selectedProductID = product.id
        } label: {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(planTitle(for: product))
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if product.id == SubscriptionManager.quarterlyProductID {
                            bestValueChip
                        }
                    }
                    if let period = product.subscription?.subscriptionPeriod {
                        Text("\(product.displayPrice) \(billingLabel(for: period))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
    }

    private var bestValueChip: some View {
        Text("BEST VALUE")
            .font(.system(size: 10, weight: .bold))
            .tracking(0.4)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.accentColor, in: Capsule())
            .foregroundStyle(.white)
    }

    // "Monthly" / "Every 3 months" per the product's own StoreKit period — never a
    // hard-coded label tied to a specific product ID, so this stays correct if the
    // durations are ever reconfigured in App Store Connect.
    private func planTitle(for product: Product) -> String {
        guard let period = product.subscription?.subscriptionPeriod else { return product.displayName }
        switch (period.unit, period.value) {
        case (.month, 1): return "Monthly"
        case (.month, let n): return "Every \(n) Months"
        case (.year, 1): return "Yearly"
        case (.week, 1): return "Weekly"
        case (.day, 1): return "Daily"
        default: return product.displayName
        }
    }

    // The FULL amount charged for that period (StoreKit's displayPrice already is the
    // total for the period, never a computed monthly-equivalent) — e.g. "$2.99 billed
    // every 3 months", not "$1.00/mo".
    private func billingLabel(for period: Product.SubscriptionPeriod) -> String {
        switch (period.unit, period.value) {
        case (.month, 1): return "per month"
        case (.year, 1): return "per year"
        case (.week, 1): return "per week"
        case (.day, 1): return "per day"
        case (.month, let n): return "billed every \(n) months"
        case (.year, let n): return "billed every \(n) years"
        case (.week, let n): return "billed every \(n) weeks"
        case (.day, let n): return "billed every \(n) days"
        @unknown default: return ""
        }
    }

    private var legalLinks: some View {
        HStack(spacing: 16) {
            if let termsURL = AppLinks.termsOfUseURL {
                Link("Terms of Use", destination: termsURL)
            }
            if let privacyURL = AppLinks.privacyPolicyURL {
                Link("Privacy Policy", destination: privacyURL)
            }
        }
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func subscribe() {
        guard let product = selectedProduct else { return }
        errorMessage = nil
        purchaseState = .purchasing
        Task {
            do {
                let outcome = try await subscriptionManager.purchase(product)
                switch outcome {
                case .success:
                    purchaseState = .verifying
                    if subscriptionManager.hasActiveSubscription {
                        purchaseState = .idle
                        onPurchaseCompleted()
                    } else {
                        purchaseState = .idle
                        errorMessage = "Your purchase went through, but we're still waiting on confirmation. This usually resolves in a moment — try again, or check Manage Subscription in Settings."
                    }
                case .pending:
                    purchaseState = .pending
                case .userCancelled:
                    purchaseState = .idle
                }
            } catch {
                purchaseState = .idle
                errorMessage = "Something went wrong completing your purchase. Please try again."
            }
        }
    }

    private func restore() {
        errorMessage = nil
        purchaseState = .restoring
        Task {
            do {
                try await subscriptionManager.restore()
                purchaseState = .idle
                if subscriptionManager.hasActiveSubscription {
                    onPurchaseCompleted()
                } else {
                    errorMessage = "No active subscription was found for this Apple ID."
                }
            } catch {
                purchaseState = .idle
                errorMessage = "Couldn't restore purchases. Please try again."
            }
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager())
}
