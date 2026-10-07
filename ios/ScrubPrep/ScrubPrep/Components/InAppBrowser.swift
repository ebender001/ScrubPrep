import SafariServices
import SwiftUI

extension View {
    /// Opens web links (every `Link` below this view) in an in-app Safari view, starting in
    /// Reader mode when the page supports it, so a student reading a citation stays in the
    /// app and gets readable text instead of a desktop page. Other links — `mailto:`, and
    /// App Store links like Manage Subscription — still go to their apps.
    ///
    /// Apply once at the root, and again inside any sheet that contains links: a sheet
    /// can't present this browser from the root while it's showing.
    func inAppBrowser() -> some View {
        modifier(InAppBrowserModifier())
    }
}

private struct InAppBrowserModifier: ViewModifier {
    @State private var presentedURL: IdentifiableURL?

    func body(content: Content) -> some View {
        content
            .environment(\.openURL, OpenURLAction { url in
                guard Self.opensInApp(url) else { return .systemAction }
                presentedURL = IdentifiableURL(url: url)
                return .handled
            })
            .fullScreenCover(item: $presentedURL) { item in
                SafariView(url: item.url)
                    .ignoresSafeArea()
            }
    }

    private static func opensInApp(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return false
        }
        // App Store pages (e.g. subscription management) belong in the App Store app.
        return url.host?.lowercased() != "apps.apple.com"
    }
}

private struct IdentifiableURL: Identifiable {
    let url: URL
    var id: URL { url }
}

/// `SFSafariViewController` for SwiftUI — Safari's own in-app browser, with a Done button,
/// Reader mode, and the user's Safari settings and content blockers.
private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = true
        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.preferredControlTintColor = UIColor(named: "AccentColor")
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
