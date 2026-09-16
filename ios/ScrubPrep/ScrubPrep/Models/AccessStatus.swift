import Foundation

/// Mirrors the backend's `getAccessStatus`/`syncSubscriptionStatus` response shape (see
/// backend/cloud/scrubPrep/subscriptions.js) — the single source of truth for whether the
/// student may generate a new case and what their subscription looks like. `nonisolated`:
/// see ORPrep's note — crosses actor boundaries as a ParseCloudable ReturnType.
nonisolated struct AccessStatus: Codable, Equatable {
    /// `status` is `none|active|grace_period|billing_retry|expired|revoked` — for display
    /// only; `isActive` is the one thing that actually gates access.
    nonisolated struct Subscription: Codable, Equatable {
        let isActive: Bool
        let status: String
        let productId: String?
        private let expiresAtRaw: String?
        private let accessEndsAtRaw: String?
        let autoRenewStatus: Bool?
        let autoRenewProductId: String?

        enum CodingKeys: String, CodingKey {
            case isActive, status, productId, autoRenewStatus, autoRenewProductId
            case expiresAtRaw = "expiresAt"
            case accessEndsAtRaw = "accessEndsAt"
        }

        // Dates arrive as plain ISO8601 strings (see ScrubCase for the same convention)
        // rather than relying on however ParseCloudable's decoder would otherwise handle
        // a native Date.
        var expiresAt: Date? { expiresAtRaw.flatMap(AccessStatus.isoFormatter.date) }
        /// When to show as "access ends" in UI — the grace-period date while in grace,
        /// otherwise the plain expiry.
        var accessEndsAt: Date? { accessEndsAtRaw.flatMap(AccessStatus.isoFormatter.date) }

        // The compiler-synthesized memberwise init would be `private` (the raw date
        // strings are private) — this is the constructor other files (MockScrubPrepService,
        // previews) actually use.
        init(
            isActive: Bool,
            status: String,
            productId: String?,
            expiresAt: Date?,
            accessEndsAt: Date?,
            autoRenewStatus: Bool?,
            autoRenewProductId: String?
        ) {
            self.isActive = isActive
            self.status = status
            self.productId = productId
            self.expiresAtRaw = expiresAt.map(AccessStatus.isoFormatter.string)
            self.accessEndsAtRaw = accessEndsAt.map(AccessStatus.isoFormatter.string)
            self.autoRenewStatus = autoRenewStatus
            self.autoRenewProductId = autoRenewProductId
        }

        static let none = Subscription(
            isActive: false,
            status: "none",
            productId: nil,
            expiresAt: nil,
            accessEndsAt: nil,
            autoRenewStatus: nil,
            autoRenewProductId: nil
        )
    }

    let appAccountToken: String
    let canGenerateNewCase: Bool
    let hasUsedComplimentaryCase: Bool
    let subscription: Subscription

    // `nonisolated(unsafe)`: ISO8601DateFormatter isn't Sendable, but this instance is
    // only ever used for read-only date(from:) calls after configuration, which is safe
    // to share across threads in practice — same pattern as ScrubCase.
    nonisolated(unsafe) fileprivate static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
