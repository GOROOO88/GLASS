import Foundation
import WebKit
import Combine

@MainActor
final class BrowserTab: NSObject, ObservableObject, Identifiable, WKNavigationDelegate, WKDownloadDelegate, WKUIDelegate {
    let id: UUID
    let webView: WKWebView
    @Published var spaceID: String
    let isPrivate: Bool
    var onVisit: ((URL, String) -> Void)?
    var onOpenInNewTab: ((URL, String, String) -> Void)?
    var onDownloadStarted: ((UUID, String, URL?) -> Void)?
    var onDownloadProgress: ((UUID, Double) -> Void)?
    var onDownloadFinished: ((UUID, URL, String, URL?) -> Void)?
    var onDownloadFailure: ((UUID, String) -> Void)?

    @Published var title = "New Tab"
    @Published var address = ""
    @Published var groupKind = "new"
    @Published var groupDetail = ""
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false

    private var downloadDestinations: [ObjectIdentifier: URL] = [:]
    private var downloadNames: [ObjectIdentifier: String] = [:]
    private var downloadSources: [ObjectIdentifier: URL] = [:]
    private var downloadIDs: [ObjectIdentifier: UUID] = [:]
    private var progressObservers: [ObjectIdentifier: NSKeyValueObservation] = [:]
    private var downloadObjects: [ObjectIdentifier: WKDownload] = [:]

    init(id: UUID = UUID(), spaceID: String = "personal", isPrivate: Bool = false) {
        self.id = id
        self.spaceID = spaceID
        self.isPrivate = isPrivate
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = isPrivate ? .nonPersistent() : .default()
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
    }

    func applyContentBlocking(adBlocking: Bool, trackerBlocking: Bool) {
        guard let store = WKContentRuleListStore.default() else { return }
        let identifier = "glass-content-protection"
        let rules: [[String: Any]] = [
            ["trigger": ["url-filter": ".*", "if-domain": ["*doubleclick.net", "*googlesyndication.com", "*adservice.google.com", "*adnxs.com", "*adform.net", "*adsrvr.org", "*taboola.com", "*outbrain.com"], "load-type": ["third-party"]], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*", "if-domain": ["*google-analytics.com", "*googletagmanager.com", "*connect.facebook.net", "*hotjar.com", "*mixpanel.com", "*segment.io", "*scorecardresearch.com"], "load-type": ["third-party"]], "action": ["type": "block"]]
        ]
        let enabledRules = rules.enumerated().compactMap { index, rule -> [String: Any]? in
            if index == 0 && !adBlocking { return nil }
            if index == 1 && !trackerBlocking { return nil }
            return rule
        }
        webView.configuration.userContentController.removeAllContentRuleLists()
        guard !enabledRules.isEmpty, let data = try? JSONSerialization.data(withJSONObject: enabledRules),
              let json = String(data: data, encoding: .utf8) else { return }
        store.compileContentRuleList(forIdentifier: identifier, encodedContentRuleList: json) { [weak self] list, _ in
            guard let self, let list else { return }
            Task { @MainActor in
                self.webView.configuration.userContentController.add(list)
            }
        }
    }

    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        let data = UserDefaults.standard.data(forKey: "glass.ios.settings.v1")
        let settings = data.flatMap { try? JSONDecoder().decode(GlassBrowserSettings.self, from: $0) } ?? GlassBrowserSettings()
        let siteRule = settings.sitePermissions[origin.host.lowercased()]
        let allowed: Bool
        switch type {
        case .camera: allowed = siteRule?.cameraAllowed ?? settings.cameraAllowed
        case .microphone: allowed = siteRule?.microphoneAllowed ?? settings.microphoneAllowed
        case .cameraAndMicrophone:
            allowed = (siteRule?.cameraAllowed ?? settings.cameraAllowed) && (siteRule?.microphoneAllowed ?? settings.microphoneAllowed)
        @unknown default: allowed = false
        }
        decisionHandler(allowed ? .grant : .deny)
    }

    func load(_ url: URL) {
        if let query = searchQuery(in: url) {
            groupKind = "search"
            groupDetail = query
        } else {
            groupKind = "direct"
            groupDetail = url.host ?? ""
        }
        webView.load(URLRequest(url: url))
    }

    private func searchQuery(in url: URL) -> String? {
        let host = (url.host ?? "").lowercased()
        let searchHosts = ["google.", "bing.com", "duckduckgo.com", "yandex.", "search.yahoo.com", "search.brave.com"]
        guard searchHosts.contains(where: { host.contains($0) }) else { return nil }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let query = items.first(where: { ["q", "text", "query", "p"].contains($0.name.lowercased()) })?.value
        return query?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? query : nil
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

    func cancelDownload(id: UUID) {
        guard let pair = downloadIDs.first(where: { $0.value == id }),
              let download = downloadObjects[pair.key] else { return }
        download.cancel { _ in }
    }

    func retryDownload(_ url: URL) {
        webView.startDownload(using: URLRequest(url: url)) { [weak self] download in
            guard let self else { return }
            download.delegate = self
            self.track(download)
        }
    }

    private func track(_ download: WKDownload) {
        let key = ObjectIdentifier(download)
        let id = downloadIDs[key] ?? UUID()
        downloadIDs[key] = id
        downloadObjects[key] = download
        progressObservers[key] = download.progress.observe(\.fractionCompleted, options: [.initial, .new]) { [weak self] progress, _ in
            let value = progress.fractionCompleted
            Task { @MainActor in self?.onDownloadProgress?(id, value) }
        }
    }

    private func refreshState() {
        address = webView.url?.absoluteString ?? address
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        isLoading = webView.isLoading
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil,
              let destinationURL = navigationAction.request.url else { return nil }
        let sourceURL = webView.url ?? navigationAction.sourceFrame.request.url
        let sourceHost = (sourceURL?.host ?? "").lowercased()
        let searchHosts = ["google.", "bing.com", "duckduckgo.com", "yandex.", "search.yahoo.com", "search.brave.com"]
        let isSearchSource = searchHosts.contains(where: { sourceHost.contains($0) })
        let query = sourceURL.flatMap { url in
            URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?
                .first(where: { ["q", "text", "query", "p"].contains($0.name.lowercased()) })?.value
        } ?? ""
        onOpenInNewTab?(destinationURL, isSearchSource ? "searchResult" : "opened", isSearchSource ? query : (sourceURL?.host ?? ""))
        return nil
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.targetFrame?.isMainFrame != false,
           let sourceURL = webView.url ?? navigationAction.sourceFrame.request.url,
           let destinationURL = navigationAction.request.url,
           sourceURL.host != destinationURL.host {
            let sourceHost = (sourceURL.host ?? "").lowercased()
            let searchHosts = ["google.", "bing.com", "duckduckgo.com", "yandex.", "search.yahoo.com", "search.brave.com"]
            if searchHosts.contains(where: { sourceHost.contains($0) }) {
                groupKind = "searchResult"
                groupDetail = URLComponents(url: sourceURL, resolvingAgainstBaseURL: false)?.queryItems?
                    .first(where: { ["q", "text", "query", "p"].contains($0.name.lowercased()) })?.value ?? ""
            } else if navigationAction.navigationType == .linkActivated {
                groupKind = "opened"
                groupDetail = sourceURL.host ?? ""
            }
        }
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
        track(download)
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
        track(download)
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
            let id = downloadIDs[key] ?? UUID()
            downloadIDs[key] = id
            onDownloadStarted?(id, filename, response.url)
            completionHandler(destination)
        } catch {
            completionHandler(nil)
        }
    }

    func downloadDidFinish(_ download: WKDownload) {
        let key = ObjectIdentifier(download)
        if let destination = downloadDestinations.removeValue(forKey: key) {
            let filename = downloadNames.removeValue(forKey: key) ?? destination.lastPathComponent
            let source = downloadSources.removeValue(forKey: key)
            let id = downloadIDs[key] ?? UUID()
            if !isPrivate {
                onDownloadFinished?(id, destination, filename, source)
            } else {
                try? FileManager.default.removeItem(at: destination)
            }
        }
        cleanupDownload(key)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        let key = ObjectIdentifier(download)
        let id = downloadIDs[key] ?? UUID()
        downloadDestinations.removeValue(forKey: key)
        downloadNames.removeValue(forKey: key)
        downloadSources.removeValue(forKey: key)
        cleanupDownload(key)
        if !isPrivate {
            onDownloadFailure?(id, error.localizedDescription)
        }
    }

    private func cleanupDownload(_ key: ObjectIdentifier) {
        progressObservers.removeValue(forKey: key)?.invalidate()
        downloadIDs.removeValue(forKey: key)
        downloadObjects.removeValue(forKey: key)
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
