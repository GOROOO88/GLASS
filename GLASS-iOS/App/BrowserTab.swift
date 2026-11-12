import Foundation
import WebKit
import Combine

@MainActor
final class BrowserTab: NSObject, ObservableObject, Identifiable, WKNavigationDelegate {
    let id = UUID()
    let webView: WKWebView

    @Published var title = "New Tab"
    @Published var address = ""
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false

    init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
    }

    func load(_ url: URL) {
        webView.load(URLRequest(url: url))
    }

    func goBack() {
        guard webView.canGoBack else { return }
        webView.goBack()
    }

    func goForward() {
        guard webView.canGoForward else { return }
        webView.goForward()
    }

    func reload() {
        webView.reload()
    }

    private func refreshState() {
        address = webView.url?.absoluteString ?? address
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        isLoading = webView.isLoading
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
        refreshState()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        title = webView.title?.isEmpty == false ? (webView.title ?? "New Tab") : (webView.url?.host ?? "New Tab")
        refreshState()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        refreshState()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        refreshState()
    }
}
