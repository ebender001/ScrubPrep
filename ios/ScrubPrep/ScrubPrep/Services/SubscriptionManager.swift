import Foundation
import StoreKit

/// Owns everything StoreKit 2: loading the two subscription products, purchasing,
/// restoring, and keeping a live transaction listener running for the app's lifetime.
///
/// Trust model: subscription access is derived entirely from StoreKit 2's own verified,
/// on-device transaction data (`Transaction.currentEntitlements`) — there is no backend
/// call anywhere in this file, no reported/stored "isSubscribed" flag, and nothing here
/// is cached across launches beyond what StoreKit itself already persists. This app talks
/// to no custom subscription server, App Store Server API, or App Store Server
/// Notifications — see backend/README.md's "Subscriptions & complimentary case" section
/// for the accepted tradeoff (no independent server-side enforcement of an active
/// subscription).
@MainActor
@Observable
final class SubscriptionManager {
    // Reuse the identifiers already configured in App Store Connect / ScrubPrep.storekit.
    static let monthlyProductID = "dev.benderapps.ScrubPrep.subscription.monthly"
    static let quarterlyProductID = "dev.benderapps.ScrubPrep.subscription.quarterly"
    static let productIDs = [monthlyProductID, quarterlyProductID]

    /// What SettingsView shows for "current plan" — built from the verified `Transaction`
    /// StoreKit says is currently entitling this account, plus (best-effort) the
    /// matching `Product.SubscriptionInfo` for a human-readable renewal/cancellation
    /// state. Never persisted; recomputed fresh every time `refreshEntitlements()` runs.
    struct ActiveSubscription {
        let productID: String
        let expirationDate: Date?
        let willAutoRenew: Bool
    }

    enum PurchaseOutcome {
        case success
        case pending
        case userCancelled
    }

    private(set) var products: [Product] = []
    private(set) var isLoadingProducts = false
    private(set) var productsLoadError: String?
    private(set) var activeSubscription: ActiveSubscription?

    var hasActiveSubscription: Bool { activeSubscription != nil }

    // @ObservationIgnored: not UI-facing state, and `deinit` (always nonisolated) needs to
    // access it as a plain stored property — an @Observable-tracked property's synthesized
    // accessor is @MainActor-isolated, which a nonisolated deinit can't call into.
    @ObservationIgnored
    private var updatesTask: Task<Void, Never>?

    init() {
        startTransactionListener()
        Task { await self.loadProducts() }
        Task { await self.refreshEntitlements() }
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

    /// Recomputes `activeSubscription` straight from StoreKit's own currently-valid
    /// entitlements. `Transaction.currentEntitlements` already excludes expired/revoked
    /// transactions and already reflects Apple-managed billing grace periods (Apple
    /// extends the entitlement itself during a grace period when it's enabled for the
    /// app) — so no manual expiry-date math or grace-period tracking is needed here.
    /// Call on launch, on foreground, and right after any purchase/restore/transaction
    /// update.
    func refreshEntitlements() async {
        var found: ActiveSubscription?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  Self.productIDs.contains(transaction.productID),
                  transaction.revocationDate == nil
            else { continue }
            let willAutoRenew = await currentAutoRenewStatus(forProductID: transaction.productID)
            found = ActiveSubscription(
                productID: transaction.productID,
                expirationDate: transaction.expirationDate,
                willAutoRenew: willAutoRenew
            )
        }
        activeSubscription = found
    }

    /// Only starts the actual purchase sheet once `Subscribe` is tapped — selecting a
    /// plan in the paywall never calls this on its own.
    func purchase(_ product: Product) async throws -> PurchaseOutcome {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await refreshEntitlements()
            await transaction.finish()
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
        await refreshEntitlements()
    }

    /// Kept alive for the process lifetime (this manager is injected once, at app launch)
    /// — StoreKit delivers renewals and other transaction changes here even when they
    /// didn't originate from an explicit `purchase()` call in this session. A transaction
    /// StoreKit already delivered to `purchase()` may also arrive here; recomputing
    /// entitlements and finishing an already-finished transaction are both harmless to
    /// repeat, so no de-duplication bookkeeping is needed.
    private func startTransactionListener() {
        updatesTask = Task {
            for await result in Transaction.updates {
                guard let transaction = try? checkVerified(result) else { continue }
                await refreshEntitlements()
                await transaction.finish()
            }
        }
    }

    /// Best-effort only — the active/expired decision above never depends on this
    /// succeeding (`transaction.expirationDate`/`revocationDate` alone are enough for
    /// that); this just adds "renews on ___" vs. "auto-renew is off" display detail.
    private func currentAutoRenewStatus(forProductID productID: String) async -> Bool {
        guard let product = products.first(where: { $0.id == productID }),
              let statuses = try? await product.subscription?.status,
              let status = statuses.first,
              case .verified(let renewalInfo) = status.renewalInfo
        else { return false }
        return renewalInfo.willAutoRenew
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
