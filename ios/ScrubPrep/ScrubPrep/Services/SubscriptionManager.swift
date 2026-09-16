import Combine
import Foundation
import StoreKit

/// Owns everything StoreKit 2: loading the two subscription products, purchasing,
/// restoring, and keeping a live transaction listener running for the app's lifetime.
/// `accessStatus` (from the backend's `getAccessStatus`/`syncSubscriptionStatus`) is the
/// single source of truth the rest of the app reads from.
///
/// Trust model: this app trusts StoreKit 2's own on-device verification
/// (`VerificationResult` — real Apple cryptography, just checked here rather than
/// re-checked server-side) and reports the already-verified transaction's plain fields to
/// the backend. See backend/cloud/scrubPrep/subscriptions.js's file comment for the full
/// reasoning and the accepted tradeoff — this was a deliberate simplification over
/// independently re-verifying Apple's signature server-side.
@MainActor
final class SubscriptionManager: ObservableObject {
    static let monthlyProductID = "dev.benderapps.ScrubPrep.subscription.monthly"
    static let quarterlyProductID = "dev.benderapps.ScrubPrep.subscription.quarterly"
    static let productIDs = [monthlyProductID, quarterlyProductID]

    enum PurchaseOutcome {
        case success
        case pending
        case userCancelled
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var productsLoadError: String?
    @Published private(set) var accessStatus: AccessStatus?

    var hasActiveSubscription: Bool { accessStatus?.subscription.isActive ?? false }
    var canGenerateNewCase: Bool { accessStatus?.canGenerateNewCase ?? true }

    private let service: ScrubPrepServicing
    private var updatesTask: Task<Void, Never>?

    init(service: ScrubPrepServicing? = nil) {
        self.service = service ?? ScrubPrepServiceFactory.make()
        startTransactionListener()
        Task { await self.loadProducts() }
        Task { await self.refreshAccessStatus() }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await Product.products(for: Self.productIDs)
            productsLoadError = products.isEmpty ? "These subscription options aren't available right now." : nil
        } catch {
            productsLoadError = "Couldn't load subscription options. Check your connection and try again."
        }
    }

    /// Refreshes the backend's view of access — call on launch, on foreground, and right
    /// after any purchase/restore/transaction update. The UI should always read
    /// `accessStatus`, never assume success just because a purchase call returned.
    func refreshAccessStatus() async {
        accessStatus = try? await service.getAccessStatus()
    }

    func purchase(_ product: Product) async throws -> PurchaseOutcome {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            try await reportAndFinish(verification, productID: product.id)
            await refreshAccessStatus()
            return .success
        case .userCancelled:
            return .userCancelled
        case .pending:
            return .pending
        @unknown default:
            return .pending
        }
    }

    /// "Restore Purchases" — re-syncs whatever StoreKit currently says this Apple ID owns.
    func restore() async throws {
        try await AppStore.sync()
        for await result in Transaction.currentEntitlements {
            try? await reportAndFinish(result, productID: nil)
        }
        await refreshAccessStatus()
    }

    /// Kept alive for the process lifetime (this manager is injected once, at app launch,
    /// and lives for the app's whole lifetime) — StoreKit delivers renewals, resolved
    /// pending purchases, and other transaction changes here even when they didn't
    /// originate from an explicit `purchase()` call in this session.
    private func startTransactionListener() {
        updatesTask = Task {
            for await result in Transaction.updates {
                try? await reportAndFinish(result, productID: nil)
                await refreshAccessStatus()
            }
        }
    }

    /// Verifies the transaction on-device (StoreKit 2's own check — real Apple
    /// cryptography), reports its plain fields to the backend, and only finishes the
    /// transaction once that call succeeds — so a dropped network call doesn't silently
    /// lose a transaction StoreKit thinks is already handled.
    private func reportAndFinish(_ result: VerificationResult<Transaction>, productID: String?) async throws {
        let transaction = try checkVerified(result)
        let resolvedProductID = productID ?? transaction.productID
        let renewal = await currentRenewalDetails(forProductID: resolvedProductID)
        let isRevoked = transaction.revocationDate != nil

        let report = ReportedSubscriptionStatus(
            status: statusString(renewalState: renewal?.state, isRevoked: isRevoked),
            productId: resolvedProductID,
            expiresAt: transaction.expirationDate,
            gracePeriodExpiresAt: renewal?.gracePeriodExpiresAt,
            autoRenewStatus: renewal?.autoRenewStatus,
            autoRenewProductId: renewal?.autoRenewProductId,
            originalTransactionId: String(transaction.originalID)
        )
        _ = try await service.syncSubscriptionStatus(report)
        await transaction.finish()
    }

    private struct RenewalDetails {
        let state: Product.SubscriptionInfo.RenewalState
        let autoRenewStatus: Bool
        let autoRenewProductId: String?
        let gracePeriodExpiresAt: Date?
    }

    /// Best-effort only — grace-period/auto-renew display detail. Core access
    /// (active/expired) doesn't depend on this succeeding, since `transaction.expirationDate`
    /// and `revocationDate` are always available directly on the transaction itself.
    private func currentRenewalDetails(forProductID productID: String) async -> RenewalDetails? {
        guard let product = products.first(where: { $0.id == productID }),
              let statuses = try? await product.subscription?.status,
              let status = statuses.first,
              case .verified(let renewalInfo) = status.renewalInfo
        else { return nil }
        return RenewalDetails(
            state: status.state,
            autoRenewStatus: renewalInfo.willAutoRenew,
            autoRenewProductId: renewalInfo.autoRenewPreference,
            gracePeriodExpiresAt: renewalInfo.gracePeriodExpirationDate
        )
    }

    // Revocation always wins regardless of what StoreKit's renewal state otherwise says.
    private func statusString(renewalState: Product.SubscriptionInfo.RenewalState?, isRevoked: Bool) -> String {
        if isRevoked { return "revoked" }
        guard let renewalState else { return "none" }
        switch renewalState {
        case .subscribed: return "active"
        case .inGracePeriod: return "grace_period"
        case .inBillingRetryPeriod: return "billing_retry"
        case .expired: return "expired"
        case .revoked: return "revoked"
        default: return "none"
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw ScrubPrepError.invalidResponse
        case .verified(let safe):
            return safe
        }
    }
}
