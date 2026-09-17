import Foundation

/// External legal links shown on the paywall — hosted from the `website/` directory at
/// the repo root, published via GitHub Pages (see .github/workflows/pages.yml).
/// **Before App Store submission**: confirm Pages is actually enabled and these URLs
/// resolve (Settings → Pages → Source: GitHub Actions, on the repo) — Apple requires a
/// working Privacy Policy URL in App Store Connect for any app offering subscriptions,
/// and a Terms of Use link is expected in the purchase flow itself per App Review
/// Guideline 3.1.2. If a custom domain is set up instead of the default
/// github.io one, update these two URLs to match.
enum AppLinks {
    static let termsOfUseURL: URL? = URL(string: "https://ebender001.github.io/ScrubPrep/terms.html")
    static let privacyPolicyURL: URL? = URL(string: "https://ebender001.github.io/ScrubPrep/privacy.html")
}
