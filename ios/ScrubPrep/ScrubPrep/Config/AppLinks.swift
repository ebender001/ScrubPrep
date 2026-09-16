import Foundation

/// External legal links shown on the paywall. `nil` until real hosted pages exist —
/// deliberately not filled with placeholder/invented URLs (see PaywallView, which omits
/// the corresponding row entirely when `nil` rather than showing a broken or fake link).
/// **Required before App Store submission**: Apple requires a working Privacy Policy URL
/// in App Store Connect for any app offering subscriptions, and a Terms of Use link is
/// expected in the purchase flow itself per App Review Guideline 3.1.2.
enum AppLinks {
    static let termsOfUseURL: URL? = nil
    static let privacyPolicyURL: URL? = nil
}
