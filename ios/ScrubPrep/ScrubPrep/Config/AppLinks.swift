import Foundation

/// External legal links shown on the paywall — hosted from the `website/` directory at
/// the repo root, published via GitHub Pages (see .github/workflows/pages.yml) at the
/// scrubprep.app custom domain. Apple requires a working Privacy Policy URL in App Store
/// Connect for any app offering subscriptions, and a Terms of Use link is expected in the
/// purchase flow itself per App Review Guideline 3.1.2.
enum AppLinks {
    static let termsOfUseURL: URL? = URL(string: "https://scrubprep.app/terms.html")
    static let privacyPolicyURL: URL? = URL(string: "https://scrubprep.app/privacy.html")
}
