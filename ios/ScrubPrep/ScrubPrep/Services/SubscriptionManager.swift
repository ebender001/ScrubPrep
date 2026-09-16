import Combine
import Foundation
import StoreKit

/// Owns everything StoreKit 2: loading the two subscription products, purchasing,
/// restoring, and keeping a live transaction listener running for the app's lifetime.
/// `accessStatus` (from the backend's `getAccessStatus`/`syncSubscriptionStatus`) is the
/// single source of truth the rest of the app reads from — this class never decides
/// access on its own, it only reports what StoreKit says and keeps the backend in sync.
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
    private var cachedAppAccountToken: UUID?

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
        let token = try await resolvedAppAccountToken()
        let result = try await product.purchase(options: [.appAccountToken(token)])
        switch result {
        case .success(let verification):
            try await verifyAndSync(verification, productID: product.id)
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
            try? await verifyAndSync(result, productID: nil)
        }
        await refreshAccessStatus()
    }

    private func resolvedAppAccountToken() async throws -> UUID {
        if let cachedAppAccountToken { return cachedAppAccountToken }
        let status = try await service.getAccessStatus()
        accessStatus = status
        guard let token = UUID(uuidString: status.appAccountToken) else {
            throw ScrubPrepError.invalidResponse
        }
        cachedAppAccountToken = token
        return token
    }

    /// Kept alive for the process lifetime (this manager is injected once, at app launch,
    /// and lives for the app's whole lifetime) — StoreKit delivers renewals, resolved
    /// pending purchases, and other transaction changes here even when they didn't
    /// originate from an explicit `purchase()` call in this session.
    private func startTransactionListener() {
        updatesTask = Task {
            for await result in Transaction.updates {
                try? await verifyAndSync(result, productID: nil)
                await refreshAccessStatus()
            }
        }
    }

    /// Verifies the transaction's signature locally (StoreKit 2's own check), submits its
    /// raw signed JWS to the backend for server-side verification, and only finishes the
    /// transaction once that backend call succeeds — so a dropped network call doesn't
    /// silently lose a transaction StoreKit thinks is already handled.
    private func verifyAndSync(_ result: VerificationResult<Transaction>, productID: String?) async throws {
        let signedTransactionInfo = result.jwsRepresentation
        let transaction = try checkVerified(result)
        _ = try await service.syncSubscriptionStatus(
            signedTransactionInfo: signedTransactionInfo,
            signedRenewalInfo: await renewalInfoJWS(forProductID: productID ?? transaction.productID)
        )
        await transaction.finish()
    }

    /// Best-effort only — grace-period/auto-renew display detail, not core access
    /// enforcement (which only needs the transaction's own expiry/revocation fields).
    private func renewalInfoJWS(forProductID productID: String) async -> String? {
        guard let product = products.first(where: { $0.id == productID }),
              let statuses = try? await product.subscription?.status,
              let status = statuses.first
        else { return nil }
        return status.renewalInfo.jwsRepresentation
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
