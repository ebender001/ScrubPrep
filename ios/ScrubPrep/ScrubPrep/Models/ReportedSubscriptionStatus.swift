import Foundation

/// What `SubscriptionManager` reports to the backend after StoreKit 2's own on-device
/// verification of a transaction — see `syncSubscriptionStatus` in
/// backend/cloud/scrubPrep/subscriptions.js. The backend trusts these fields rather than
/// independently re-verifying Apple's signature (a deliberate simplification — see that
/// file's comment); dates are sent as ISO8601 strings, matching this app's established
/// convention for not relying on however a Cloud Function param encoder would otherwise
/// handle a native `Date`.
nonisolated struct ReportedSubscriptionStatus: Codable {
    /// `none|active|grace_period|billing_retry|expired|revoked`.
    let status: String
    let productId: String?
    let expiresAt: String?
    let gracePeriodExpiresAt: String?
    let autoRenewStatus: Bool?
    let autoRenewProductId: String?
    let originalTransactionId: String?
    /// The `appAccountToken` StoreKit reports on the underlying `Transaction` (read
    /// directly off the already-verified transaction, no decoding needed) — lets the
    /// backend reject a transaction that doesn't actually belong to this account. `nil`
    /// when StoreKit didn't report one (e.g. a transaction predating this app ever
    /// setting one), in which case the backend applies the report leniently.
    let appAccountToken: String?

    // `nonisolated(unsafe)`: see AccessStatus's identical note.
    nonisolated(unsafe) private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    init(
        status: String,
        productId: String?,
        expiresAt: Date?,
        gracePeriodExpiresAt: Date?,
        autoRenewStatus: Bool?,
        autoRenewProductId: String?,
        originalTransactionId: String?,
        appAccountToken: String?
    ) {
        self.status = status
        self.productId = productId
        self.expiresAt = expiresAt.map(Self.isoFormatter.string)
        self.gracePeriodExpiresAt = gracePeriodExpiresAt.map(Self.isoFormatter.string)
        self.autoRenewStatus = autoRenewStatus
        self.autoRenewProductId = autoRenewProductId
        self.originalTransactionId = originalTransactionId
        self.appAccountToken = appAccountToken
    }
}
