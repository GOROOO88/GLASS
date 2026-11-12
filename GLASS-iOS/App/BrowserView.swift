import SwiftUI
import WebKit

struct BrowserView: UIViewRepresentable {
    let tab: BrowserTab

    func makeUIView(context: Context) -> WKWebView {
        tab.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Navigation is driven by BrowserTab; avoid reloading during SwiftUI updates.
    }
}
