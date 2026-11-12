import Foundation
import WebKit
import Combine

@MainActor
final class BrowserTab: NSObject, ObservableObject, Identifiable, WKNavigationDelegate, WKDownloadDelegate {
    let id: UUID
    let webView: WKWebView
    @Published var spaceID: String
    let isPrivate: Bool
    var onVisit: ((URL, String) -> Void)?
    var onDownload: ((URL, String, URL?) -> Void)?
    var onDownloadFailure: ((String) -> Void)?

    @Published var title = "New Tab"
    @Published var address = ""
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false

    private var downloadDestinations: [ObjectIdentifier: URL] = [:]
    private var downloadNames: [ObjectIdentifier: String] = [:]
    private var downloadSources: [ObjectIdentifier: URL] = [:]

    init(id: UUID = UUID(), spaceID: String = "personal", isPrivate: Bool = false) {
        self.id = id
        self.spaceID = spaceID
        self.isPrivate = isPrivate
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = isPrivate ? .nonPersistent() : .default()
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
    }

    func load(_ url: URL) {
        webView.load(URLRequest(url: url))
    }

    func loadFile(_ url: URL) {
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
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

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.shouldPerformDownload {
            decisionHandler(.download)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(navigationResponse.canShowMIMEType ? .allow : .download)
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let manager = FileManager.default
        guard let documents = manager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            completionHandler(nil)
            return
        }
        let folder = documents.appendingPathComponent("Downloads", isDirectory: true)
        do {
            try manager.createDirectory(at: folder, withIntermediateDirectories: true)
            let safeName = URL(fileURLWithPath: suggestedFilename).lastPathComponent
            let filename = safeName.isEmpty ? "download-\(UUID().uuidString)" : safeName
            let destination = folder.appendingPathComponent("\(UUID().uuidString.prefix(8))-\(filename)")
            let key = ObjectIdentifier(download)
            downloadDestinations[key] = destination
            downloadNames[key] = filename
            downloadSources[key] = response.url
            completionHandler(destination)
        } catch {
            completionHandler(nil)
            onDownloadFailure?(error.localizedDescription)
        }
    }

    func downloadDidFinish(_ download: WKDownload) {
        let key = ObjectIdentifier(download)
        if let destination = downloadDestinations.removeValue(forKey: key) {
            let filename = downloadNames.removeValue(forKey: key) ?? destination.lastPathComponent
            let source = downloadSources.removeValue(forKey: key)
            if !isPrivate {
                onDownload?(destination, filename, source)
            }
        }
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        let key = ObjectIdentifier(download)
        downloadDestinations.removeValue(forKey: key)
        downloadNames.removeValue(forKey: key)
        downloadSources.removeValue(forKey: key)
        onDownloadFailure?(error.localizedDescription)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
        refreshState()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        title = webView.title?.isEmpty == false ? (webView.title ?? "New Tab") : (webView.url?.host ?? "New Tab")
        refreshState()
        if !isPrivate, let url = webView.url {
            onVisit?(url, title)
        }
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
