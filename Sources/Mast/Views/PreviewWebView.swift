import SwiftUI
import WebKit

struct PreviewWebView: NSViewRepresentable {
    let url: URL
    var onNavigate: (URL) -> Void = { _ in }

    func makeCoordinator() -> Coordinator {
        Coordinator(onNavigate: onNavigate)
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.onNavigate = onNavigate
        guard webView.url != url else { return }
        webView.load(URLRequest(url: url))
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        var onNavigate: (URL) -> Void

        init(onNavigate: @escaping (URL) -> Void) {
            self.onNavigate = onNavigate
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let url = webView.url else { return }
            onNavigate(url)
        }
    }
}
