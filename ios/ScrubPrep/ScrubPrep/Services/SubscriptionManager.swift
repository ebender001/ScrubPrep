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
    // TEMPORARY diagnostic — remove once the "couldn't confirm" investigation is closed.
    // Captures exactly what the last transaction report sent and what the backend handed
    // back, so a failure to apply can be seen without attaching a debugger.
    @Published private(set) var lastSyncDebugDescription: String?

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
        if let status = try? await service.getAccessStatus() {
            accessStatus = status
        }
    }

    /// This account's own `appAccountToken` — always fetched fresh (never cached across
    /// calls) so it's guaranteed to belong to whoever is *currently* signed in. This
    /// manager is created once and lives for the app's whole process lifetime, so caching
    /// this across a sign-out/sign-in as a different account would silently send a stale,
    /// mismatched token — exactly the bug this was fixed from. The extra round trip only
    /// happens right before a purchase, not on any hot path.
    private func resolvedAppAccountToken() async -> UUID? {
        await refreshAccessStatus()
        return accessStatus.flatMap { UUID(uuidString: $0.appAccountToken) }
    }

    func purchase(_ product: Product) async throws -> PurchaseOutcome {
        let ownToken = await resolvedAppAccountToken()
        var options: Set<Product.PurchaseOption> = []
        if let ownToken {
            options.insert(.appAccountToken(ownToken))
        }
        let result = try await product.purchase(options: options)
        switch result {
        case .success(let verification):
            // Pass the exact token we just used, rather than reading it back off the
            // transaction — a direct purchase this account just made is unambiguously
            // theirs regardless of whether StoreKit faithfully echoes the option back
            // (local StoreKit Configuration testing isn't guaranteed to).
            try await reportAndFinish(verification, productID: product.id, knownAppAccountToken: ownToken)
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
            try? await reportAndFinish(result, productID: nil, knownAppAccountToken: nil)
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
                try? await reportAndFinish(result, productID: nil, knownAppAccountToken: nil)
                await refreshAccessStatus()
            }
        }
    }

    /// Verifies the transaction on-device (StoreKit 2's own check — real Apple
    /// cryptography), reports its plain fields to the backend, and only finishes the
    /// transaction once that call succeeds — so a dropped network call doesn't silently
    /// lose a transaction StoreKit thinks is already handled. `knownAppAccountToken`, when
    /// provided (a fresh purchase this account just made), takes precedence over whatever
    /// the transaction itself reports; for restore/listener-delivered transactions (where
    /// we have no other way to know whose they are) `transaction.appAccountToken` is used
    /// instead, which is what actually lets the backend reject a foreign transaction.
    private func reportAndFinish(
        _ result: VerificationResult<Transaction>,
        productID: String?,
        knownAppAccountToken: UUID?
    ) async throws {
        let transaction = try checkVerified(result)
        let resolvedProductID = productID ?? transaction.productID
        let renewal = await currentRenewalDetails(forProductID: resolvedProductID)
        let reportedToken = knownAppAccountToken?.uuidString ?? transaction.appAccountToken?.uuidString

        let report = ReportedSubscriptionStatus(
            status: statusString(transaction: transaction, renewalState: renewal?.state),
            productId: resolvedProductID,
            expiresAt: transaction.expirationDate,
            gracePeriodExpiresAt: renewal?.gracePeriodExpiresAt,
            autoRenewStatus: renewal?.autoRenewStatus,
            autoRenewProductId: renewal?.autoRenewProductId,
            originalTransactionId: String(transaction.originalID),
            appAccountToken: reportedToken
        )
        do {
            let resultStatus = try await service.syncSubscriptionStatus(report)
            lastSyncDebugDescription = """
            sent: status=\(report.status) productId=\(report.productId ?? "nil") expiresAt=\(report.expiresAt ?? "nil") token=\(report.appAccountToken ?? "nil")
            got back: isActive=\(resultStatus.subscription.isActive) status=\(resultStatus.subscription.status)
            """
        } catch {
            lastSyncDebugDescription = "syncSubscriptionStatus THREW: \(error)"
            throw error
        }
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

    /// The transaction's own `expirationDate`/`revocationDate` are always available (no
    /// async fetch needed) and are the primary signal — this must work correctly even
    /// when `currentRenewalDetails` fails or hasn't caught up yet (a real timing gap right
    /// after a fresh purchase, worse in local StoreKit testing). `renewalState` only
    /// refines grace-period/billing-retry detail on top of that; it never downgrades an
    /// otherwise-active, unexpired transaction to "none" just because it couldn't be
    /// fetched.
    private func statusString(transaction: Transaction, renewalState: Product.SubscriptionInfo.RenewalState?) -> String {
        if transaction.revocationDate != nil { return "revoked" }
        if renewalState == .inGracePeriod { return "grace_period" }
        if let expirationDate = transaction.expirationDate, expirationDate > Date() {
            return "active"
        }
        if renewalState == .inBillingRetryPeriod { return "billing_retry" }
        return "expired"
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
