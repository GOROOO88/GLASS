import Foundation
import Combine
import WebKit

enum GlassSyncRestoreError: Error {
    case unsupportedSnapshot
    case invalidSnapshot
}

struct BrowserBookmark: Codable, Identifiable, Equatable {
    var id: String { url }
    let title: String
    let url: String
}

struct RecentlyClosedTab: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let url: String
    let spaceID: String
    let groupKind: String
    let groupDetail: String
    let closedAt: Date

    init(tab: BrowserTab) {
        id = UUID()
        title = tab.title.isEmpty ? (URL(string: tab.address)?.host ?? "Closed tab") : tab.title
        url = tab.address
        spaceID = tab.spaceID
        groupKind = tab.groupKind
        groupDetail = tab.groupDetail
        closedAt = Date()
    }
}
struct BrowserDownload: Codable, Identifiable, Equatable {
    let id: UUID
    let filename: String
    let localPath: String
    let sourceURL: String?
    let completedAt: Date

    init(id: UUID = UUID(), filename: String, localURL: URL, sourceURL: URL?) {
        self.id = id
        self.filename = filename
        localPath = localURL.path
        self.sourceURL = sourceURL?.absoluteString
        completedAt = Date()
    }

    var fileURL: URL { URL(fileURLWithPath: localPath) }
}

struct ActiveBrowserDownload: Identifiable, Equatable {
    let id: UUID
    var filename: String
    var sourceURL: String?
    var progress: Double
    var failure: String?
}

struct BrowserSpace: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var symbol: String
    var tint: String

    static let defaults = [
        BrowserSpace(id: "personal", name: "Personal", symbol: "person", tint: "violet"),
        BrowserSpace(id: "gaming", name: "Gaming", symbol: "gamecontroller", tint: "green"),
        BrowserSpace(id: "work", name: "Work", symbol: "briefcase", tint: "blue"),
        BrowserSpace(id: "shopping", name: "Shopping", symbol: "bag", tint: "orange")
    ]
}

private struct SavedBrowserTab: Codable {
    let id: UUID
    let spaceID: String
    let address: String
    let groupKind: String?
    let groupDetail: String?
}

private struct SavedBrowserSession: Codable {
    let tabs: [SavedBrowserTab]
    let activeTabID: UUID?
    let activeSpaceID: String
}

@MainActor
final class BrowserStore: ObservableObject {
    @Published private(set) var tabs: [BrowserTab] = []
    @Published var activeTabID: UUID?
    @Published private(set) var history: [String] = []
    @Published private(set) var recentlyClosed: [RecentlyClosedTab] = []
    @Published private(set) var bookmarks: [BrowserBookmark] = []
    @Published private(set) var downloads: [BrowserDownload] = []
    @Published private(set) var activeDownloads: [ActiveBrowserDownload] = []
    private var downloadOwners: [UUID: BrowserTab] = [:]
    private var tabStateObservers: [UUID: AnyCancellable] = [:]
    @Published private(set) var spaces: [BrowserSpace] = []
    @Published var activeSpaceID = "personal"
    @Published private(set) var settings = GlassBrowserSettings()

    private let historyKey = "glass.ios.history.v1"
    private let recentlyClosedKey = "glass.ios.recentlyClosed.v1"
    private let bookmarksKey = "glass.ios.bookmarks.v1"
    private let downloadsKey = "glass.ios.downloads.v1"
    private let spacesKey = "glass.ios.spaces.v1"
    private let sessionKey = "glass.ios.session.v1"
    private let settingsKey = "glass.ios.settings.v1"

    init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: settingsKey),
           let savedSettings = try? JSONDecoder().decode(GlassBrowserSettings.self, from: data) {
            settings = savedSettings
        }
        history = defaults.stringArray(forKey: historyKey) ?? []
        if let data = defaults.data(forKey: recentlyClosedKey),
           let saved = try? JSONDecoder().decode([RecentlyClosedTab].self, from: data) {
            recentlyClosed = saved
        }
        if let data = defaults.data(forKey: bookmarksKey),
           let saved = try? JSONDecoder().decode([BrowserBookmark].self, from: data) {
            bookmarks = saved
        }
        if let data = defaults.data(forKey: downloadsKey),
           let saved = try? JSONDecoder().decode([BrowserDownload].self, from: data) {
            downloads = saved.filter { FileManager.default.fileExists(atPath: $0.localPath) }
        }
        if let data = defaults.data(forKey: spacesKey),
           let saved = try? JSONDecoder().decode([BrowserSpace].self, from: data), !saved.isEmpty {
            spaces = saved
        } else {
            spaces = BrowserSpace.defaults
        }

        var restoredTabs: [SavedBrowserTab] = []
        var restoredActiveTabID: UUID?
        var restoredActiveSpaceID = "personal"
        if let data = defaults.data(forKey: sessionKey) {
            if let session = try? JSONDecoder().decode(SavedBrowserSession.self, from: data) {
                restoredTabs = session.tabs
                restoredActiveTabID = session.activeTabID
                restoredActiveSpaceID = session.activeSpaceID
            } else {
                // Backward compatibility with the earlier v1 array-only session format.
                restoredTabs = (try? JSONDecoder().decode([SavedBrowserTab].self, from: data)) ?? []
            }
        }
        if restoredTabs.isEmpty {
            addTab(spaceID: "personal")
        } else {
            for saved in restoredTabs {
                let safeSpaceID = spaces.contains(where: { $0.id == saved.spaceID }) ? saved.spaceID : "personal"
                let tab = makeTab(id: saved.id, spaceID: safeSpaceID)
                tabs.append(tab)
                if let url = URL(string: saved.address), ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                    tab.load(url)
                }
                tab.groupKind = saved.groupKind ?? (saved.address.isEmpty ? "new" : "direct")
                tab.groupDetail = saved.groupDetail ?? ""
            }
            let safeActiveSpaceID = spaces.contains(where: { $0.id == restoredActiveSpaceID }) ? restoredActiveSpaceID : "personal"
            activeSpaceID = safeActiveSpaceID
            if let restoredActiveTabID, tabs.contains(where: { $0.id == restoredActiveTabID && $0.spaceID == safeActiveSpaceID }) {
                activeTabID = restoredActiveTabID
            } else {
                activeTabID = tabs.last(where: { $0.spaceID == safeActiveSpaceID })?.id ?? tabs.first?.id
                activeSpaceID = activeTab?.spaceID ?? "personal"
            }
        }
        saveSpaces()
        saveDownloads()
        saveSession()
    }

    var activeTab: BrowserTab? {
        tabs.first(where: { $0.id == activeTabID })
    }

    var activeSpace: BrowserSpace {
        spaces.first(where: { $0.id == activeSpaceID }) ?? BrowserSpace.defaults[0]
    }

    var visibleTabs: [BrowserTab] {
        tabs.filter { $0.spaceID == activeSpaceID }
    }

    var regularTabs: [BrowserTab] {
        tabs.filter { !$0.isPrivate }
    }

    var privateTabs: [BrowserTab] {
        tabs.filter { $0.isPrivate }
    }

    func addTab(spaceID: String? = nil, isPrivate: Bool = false) {
        let destination = spaceID ?? activeSpaceID
        let tab = makeTab(spaceID: destination, isPrivate: isPrivate)
        tabs.append(tab)
        activeSpaceID = destination
        activeTabID = tab.id
        saveSession()
    }

    func addPrivateTab() {
        addTab(spaceID: activeSpaceID, isPrivate: true)
    }

    func selectSpace(_ space: BrowserSpace) {
        activeSpaceID = space.id
        if let existing = tabs.last(where: { $0.spaceID == space.id && !$0.isPrivate }) {
            activeTabID = existing.id
            saveSession()
        } else {
            addTab(spaceID: space.id)
        }
    }

    func createSpace(name: String) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, !spaces.contains(where: { $0.name.caseInsensitiveCompare(cleanName) == .orderedSame }) else { return }
        let palette = ["violet", "blue", "green", "orange"]
        let tint = palette[spaces.count % palette.count]
        let space = BrowserSpace(id: UUID().uuidString, name: cleanName, symbol: "square.grid.2x2", tint: tint)
        spaces.append(space)
        saveSpaces()
        selectSpace(space)
    }

    func removeSpace(_ space: BrowserSpace) {
        guard space.id != "personal" else { return }
        for tab in tabs where tab.spaceID == space.id {
            tab.spaceID = "personal"
        }
        spaces.removeAll(where: { $0.id == space.id })
        if activeSpaceID == space.id {
            activeSpaceID = "personal"
            if let tab = tabs.last(where: { $0.spaceID == "personal" && !$0.isPrivate }) {
                activeTabID = tab.id
            } else {
                addTab(spaceID: "personal")
            }
        }
        saveSpaces()
        saveSession()
    }

    func move(_ tab: BrowserTab, to space: BrowserSpace) {
        tab.spaceID = space.id
        if activeTabID == tab.id {
            activeSpaceID = space.id
        }
        saveSession()
    }

    func select(_ tab: BrowserTab) {
        activeSpaceID = tab.spaceID
        activeTabID = tab.id
        saveSession()
    }

    func duplicate(_ tab: BrowserTab) {
        let copy = makeTab(spaceID: tab.spaceID, isPrivate: tab.isPrivate)
        tabs.append(copy)
        activeSpaceID = tab.spaceID
        activeTabID = copy.id
        if let url = URL(string: tab.address),
           ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
            copy.load(url)
        }
        copy.groupKind = tab.groupKind
        copy.groupDetail = tab.groupDetail
        saveSession()
    }

    func close(_ tab: BrowserTab) {
        guard let index = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        let wasActive = activeTabID == tab.id
        let oldSpaceID = tab.spaceID
        if !tab.isPrivate, !tab.address.isEmpty, URL(string: tab.address)?.scheme != nil {
            recentlyClosed.insert(RecentlyClosedTab(tab: tab), at: 0)
            recentlyClosed = Array(recentlyClosed.prefix(8))
            saveRecentlyClosed()
        }
        if tab.isPrivate && settings.clearPrivateDataOnClose {
            tab.webView.stopLoading()
            tab.webView.configuration.websiteDataStore.removeData(
                ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                modifiedSince: Date(timeIntervalSince1970: 0),
                completionHandler: {}
            )
            tab.webView.loadHTMLString("", baseURL: nil)
        }
        tabs.remove(at: index)
        tabStateObservers.removeValue(forKey: tab.id)?.cancel()

        if tabs.isEmpty {
            addTab(spaceID: oldSpaceID)
        } else if wasActive {
            activeTabID = tabs.last(where: { $0.spaceID == oldSpaceID })?.id ?? tabs.first?.id
            activeSpaceID = activeTab?.spaceID ?? "personal"
        }
        saveSession()
    }

    func reopen(_ item: RecentlyClosedTab) {
        guard let url = URL(string: item.url) else { return }
        let destination = spaces.contains(where: { $0.id == item.spaceID }) ? item.spaceID : activeSpaceID
        addTab(spaceID: destination)
        guard let tab = activeTab else { return }
        tab.load(url)
        tab.groupKind = item.groupKind
        tab.groupDetail = item.groupDetail
        recentlyClosed.removeAll { $0.id == item.id }
        saveRecentlyClosed()
    }

    func clearRecentlyClosed() {
        recentlyClosed.removeAll()
        saveRecentlyClosed()
    }

    private func saveRecentlyClosed() {
        if let data = try? JSONEncoder().encode(recentlyClosed) {
            UserDefaults.standard.set(data, forKey: recentlyClosedKey)
        }
    }
    func closeAllTabsInActiveSpace() {
        let closing = tabs.filter { $0.spaceID == activeSpaceID }
        guard !closing.isEmpty else { return }
        for tab in closing {
            if tab.isPrivate && settings.clearPrivateDataOnClose {
                tab.webView.stopLoading()
                tab.webView.configuration.websiteDataStore.removeData(
                    ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                    modifiedSince: Date(timeIntervalSince1970: 0),
                    completionHandler: {}
                )
            }
            tab.webView.stopLoading()
            tabStateObservers.removeValue(forKey: tab.id)?.cancel()
        }
        tabs.removeAll { $0.spaceID == activeSpaceID }
        addTab(spaceID: activeSpaceID)
    }

    func moveTab(_ source: BrowserTab, before destination: BrowserTab) {
        guard source.id != destination.id, source.spaceID == destination.spaceID,
              let sourceIndex = tabs.firstIndex(where: { $0.id == source.id }),
              let destinationIndex = tabs.firstIndex(where: { $0.id == destination.id }) else { return }
        let moved = tabs.remove(at: sourceIndex)
        let adjustedDestination = tabs.firstIndex(where: { $0.id == destination.id }) ?? min(destinationIndex, tabs.count)
        tabs.insert(moved, at: adjustedDestination)
        saveSession()
    }
    func closeAllPrivateTabs() {
        let privateTabs = tabs.filter { $0.isPrivate }
        privateTabs.forEach { close($0) }
    }

    func searchURL(for query: String) -> URL? {
        settings.searchEngine.searchURL(for: query)
    }

    func updateSetting<Value>(_ keyPath: WritableKeyPath<GlassBrowserSettings, Value>, value: Value) {
        settings[keyPath: keyPath] = value
        saveSettings()
        tabs.forEach { $0.applyContentBlocking(adBlocking: settings.adBlockingEnabled, trackerBlocking: settings.trackerBlockingEnabled) }
    }

    func setSitePermission(domain: String, camera: Bool, microphone: Bool) {
        let clean = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty, !clean.contains("/") else { return }
        settings.sitePermissions[clean] = BrowserSitePermission(domain: clean, cameraAllowed: camera, microphoneAllowed: microphone)
        saveSettings()
    }

    func removeSitePermission(_ domain: String) {
        settings.sitePermissions.removeValue(forKey: domain)
        saveSettings()
    }

    func updateCustomStartPage(_ value: String) {
        settings.customStartPageURL = value
        saveSettings()
    }

    var resolvedStartPageURL: URL? {
        guard settings.startPage == "custom" else { return nil }
        let value = settings.customStartPageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        if let url = URL(string: value), ["http", "https"].contains(url.scheme?.lowercased() ?? "") { return url }
        return URL(string: "https://" + value)
    }

    private func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: settingsKey)
    }

    private func makeTab(id: UUID = UUID(), spaceID: String, isPrivate: Bool = false) -> BrowserTab {
        let tab = BrowserTab(id: id, spaceID: spaceID, isPrivate: isPrivate)
        tabStateObservers[id] = Publishers.CombineLatest(tab.$groupKind, tab.$groupDetail)
            .dropFirst()
            .sink { [weak self] _, _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.saveSession()
                    self.objectWillChange.send()
                }
            }
        tab.onOpenInNewTab = { [weak self, weak tab] url, groupKind, groupDetail in
            guard let self, let tab else { return }
            self.addTab(spaceID: tab.spaceID, isPrivate: tab.isPrivate)
            guard let newTab = self.activeTab else { return }
            newTab.load(url)
            newTab.groupKind = groupKind
            newTab.groupDetail = groupDetail
        }
        tab.applyContentBlocking(adBlocking: settings.adBlockingEnabled, trackerBlocking: settings.trackerBlockingEnabled)
        if !isPrivate {
            tab.onVisit = { [weak self] url, title in
                self?.recordVisit(url, title: title)
            }
            tab.onDownloadStarted = { [weak self, weak tab] id, filename, sourceURL in
                guard let self, let tab else { return }
                self.downloadOwners[id] = tab
                self.activeDownloads.insert(ActiveBrowserDownload(id: id, filename: filename, sourceURL: sourceURL?.absoluteString, progress: 0, failure: nil), at: 0)
            }
            tab.onDownloadProgress = { [weak self] id, progress in
                guard let self, let index = self.activeDownloads.firstIndex(where: { $0.id == id }) else { return }
                self.activeDownloads[index].progress = min(max(progress, 0), 1)
            }
            tab.onDownloadFinished = { [weak self] id, fileURL, filename, sourceURL in
                guard let self else { return }
                self.activeDownloads.removeAll(where: { $0.id == id })
                self.downloadOwners.removeValue(forKey: id)
                self.recordDownload(id: id, fileURL: fileURL, filename: filename, sourceURL: sourceURL)
            }
            tab.onDownloadFailure = { [weak self] id, message in
                guard let self, let index = self.activeDownloads.firstIndex(where: { $0.id == id }) else { return }
                self.activeDownloads[index].failure = message
            }
        }
        return tab
    }

    func recordVisit(_ url: URL, title: String? = nil) {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return }
        let value = url.absoluteString
        history.removeAll(where: { $0 == value })
        history.insert(value, at: 0)
        if history.count > 500 {
            history = Array(history.prefix(500))
        }
        UserDefaults.standard.set(history, forKey: historyKey)

        if let title, let index = bookmarks.firstIndex(where: { $0.url == value }) {
            bookmarks[index] = BrowserBookmark(title: title, url: value)
            saveBookmarks()
        }
        saveSession()
    }

    func recordDownload(id: UUID = UUID(), fileURL: URL, filename: String, sourceURL: URL?) {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        downloads.insert(BrowserDownload(id: id, filename: filename, localURL: fileURL, sourceURL: sourceURL), at: 0)
        saveDownloads()
    }

    func cancelDownload(_ download: ActiveBrowserDownload) {
        downloadOwners[download.id]?.cancelDownload(id: download.id)
    }

    func retryDownload(_ download: ActiveBrowserDownload) {
        guard let value = download.sourceURL, let url = URL(string: value),
              let owner = downloadOwners[download.id], !owner.isPrivate else { return }
        activeDownloads.removeAll(where: { $0.id == download.id })
        downloadOwners.removeValue(forKey: download.id)
        owner.retryDownload(url)
    }

    func removeDownload(_ download: BrowserDownload) {
        try? FileManager.default.removeItem(at: download.fileURL)
        downloads.removeAll(where: { $0.id == download.id })
        saveDownloads()
    }

    func clearDownloads() {
        for download in downloads {
            try? FileManager.default.removeItem(at: download.fileURL)
        }
        downloads.removeAll()
        saveDownloads()
    }

    func isBookmarked(_ url: String) -> Bool {
        bookmarks.contains(where: { $0.url == url })
    }

    func toggleBookmark(url: String, title: String) {
        guard URL(string: url) != nil else { return }
        if isBookmarked(url) {
            bookmarks.removeAll(where: { $0.url == url })
        } else {
            bookmarks.insert(BrowserBookmark(title: title.isEmpty ? url : title, url: url), at: 0)
        }
        saveBookmarks()
    }

    func removeBookmark(_ bookmark: BrowserBookmark) {
        bookmarks.removeAll(where: { $0.id == bookmark.id })
        saveBookmarks()
    }

    func clearHistory() {
        history.removeAll()
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    func encryptedSyncSnapshot() throws -> String {
        let snapshot = GlassSyncSnapshot(
            schemaVersion: 1,
            createdAt: Date(),
            bookmarks: bookmarks,
            history: history,
            spaces: spaces,
            tabs: regularTabs.map {
                GlassSyncTab(id: $0.id, spaceID: $0.spaceID, address: $0.address)
            },
            activeTabID: activeTab?.isPrivate == false ? activeTabID : nil,
            activeSpaceID: activeSpaceID,
            settings: settings
        )
        return try GlassSyncVault.seal(snapshot)
    }

    func restoreEncryptedSyncSnapshot(_ envelope: String) throws {
        let snapshot = try GlassSyncVault.open(envelope, as: GlassSyncSnapshot.self)
        guard snapshot.schemaVersion == 1,
              snapshot.bookmarks.count <= 5000,
              snapshot.history.count <= 500,
              snapshot.spaces.count > 0,
              snapshot.spaces.count <= 100,
              snapshot.tabs.count <= 100 else {
            throw GlassSyncRestoreError.unsupportedSnapshot
        }

        let validSpaces = snapshot.spaces.filter {
            !$0.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard validSpaces.count == snapshot.spaces.count,
              Set(validSpaces.map(\.id)).count == validSpaces.count,
              validSpaces.contains(where: { $0.id == "personal" }),
              Set(snapshot.tabs.map(\.id)).count == snapshot.tabs.count else {
            throw GlassSyncRestoreError.invalidSnapshot
        }

        func isWebAddress(_ value: String) -> Bool {
            guard let url = URL(string: value),
                  let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https",
                  url.host != nil else { return false }
            return true
        }

        guard snapshot.bookmarks.allSatisfy({ isWebAddress($0.url) }),
              snapshot.history.allSatisfy({ isWebAddress($0) }),
              snapshot.tabs.allSatisfy({ isWebAddress($0.address) }) else {
            throw GlassSyncRestoreError.invalidSnapshot
        }

        let spaceIDs = Set(validSpaces.map(\.id))
        guard snapshot.tabs.allSatisfy({ spaceIDs.contains($0.spaceID) }) else {
            throw GlassSyncRestoreError.invalidSnapshot
        }

        let retainedPrivateTabs = tabs.filter(\.isPrivate)
        tabs = retainedPrivateTabs
        spaces = validSpaces
        bookmarks = snapshot.bookmarks
        history = snapshot.history
        settings = snapshot.settings
        activeSpaceID = spaceIDs.contains(snapshot.activeSpaceID) ? snapshot.activeSpaceID : "personal"

        for saved in snapshot.tabs {
            let tab = makeTab(id: saved.id, spaceID: saved.spaceID)
            tabs.append(tab)
            if let url = URL(string: saved.address) {
                tab.load(url)
            }
        }

        if let restoredID = snapshot.activeTabID,
           tabs.contains(where: { $0.id == restoredID && !$0.isPrivate }) {
            activeTabID = restoredID
        } else {
            activeTabID = tabs.last(where: { !$0.isPrivate && $0.spaceID == activeSpaceID })?.id
                ?? retainedPrivateTabs.last?.id
        }

        tabs.forEach {
            $0.applyContentBlocking(
                adBlocking: settings.adBlockingEnabled,
                trackerBlocking: settings.trackerBlockingEnabled
            )
        }
        saveBookmarks()
        saveSpaces()
        saveSettings()
        UserDefaults.standard.set(history, forKey: historyKey)
        saveSession()
    }

    func clearWebsiteData(completion: @escaping () -> Void) {
        let store = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        store.removeData(ofTypes: dataTypes, modifiedSince: Date(timeIntervalSince1970: 0)) {
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    private func saveBookmarks() {
        guard let data = try? JSONEncoder().encode(bookmarks) else { return }
        UserDefaults.standard.set(data, forKey: bookmarksKey)
    }

    private func saveDownloads() {
        guard let data = try? JSONEncoder().encode(downloads) else { return }
        UserDefaults.standard.set(data, forKey: downloadsKey)
    }

    private func saveSpaces() {
        guard let data = try? JSONEncoder().encode(spaces) else { return }
        UserDefaults.standard.set(data, forKey: spacesKey)
    }

    private func saveSession() {
        let savedTabs = tabs.filter { !$0.isPrivate }.map {
            SavedBrowserTab(id: $0.id, spaceID: $0.spaceID, address: $0.address, groupKind: $0.groupKind, groupDetail: $0.groupDetail)
        }
        let safeActiveTabID = activeTab?.isPrivate == false ? activeTabID : tabs.last(where: { !$0.isPrivate && $0.spaceID == activeSpaceID })?.id
        let session = SavedBrowserSession(tabs: savedTabs, activeTabID: safeActiveTabID, activeSpaceID: activeSpaceID)
        guard let data = try? JSONEncoder().encode(session) else { return }
        UserDefaults.standard.set(data, forKey: sessionKey)
    }
}
