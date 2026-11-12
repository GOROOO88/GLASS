import Foundation
import Combine\nimport WebKit

struct BrowserBookmark: Codable, Identifiable, Equatable {
    var id: String { url }
    let title: String
    let url: String
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
    @Published private(set) var bookmarks: [BrowserBookmark] = []
    @Published private(set) var downloads: [BrowserDownload] = []
    @Published private(set) var activeDownloads: [ActiveBrowserDownload] = []
    private var downloadOwners: [UUID: BrowserTab] = [:]
    @Published private(set) var spaces: [BrowserSpace] = []
    @Published var activeSpaceID = "personal"
    @Published private(set) var settings = GlassBrowserSettings()

    private let historyKey = "glass.ios.history.v1"
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

    func close(_ tab: BrowserTab) {
        guard let index = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        let wasActive = activeTabID == tab.id
        let oldSpaceID = tab.spaceID
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

        if tabs.isEmpty {
            addTab(spaceID: oldSpaceID)
        } else if wasActive {
            activeTabID = tabs.last(where: { $0.spaceID == oldSpaceID })?.id ?? tabs.first?.id
            activeSpaceID = activeTab?.spaceID ?? "personal"
        }
        saveSession()
    }

    func closeAllPrivateTabs() {\n        let privateTabs = tabs.filter { $0.isPrivate }\n        privateTabs.forEach { close($0) }\n    }\n\n    func searchURL(for query: String) -> URL? {\n        settings.searchEngine.searchURL(for: query)\n    }\n\n    func updateSetting<Value>(_ keyPath: WritableKeyPath<GlassBrowserSettings, Value>, value: Value) {\n        settings[keyPath: keyPath] = value\n        saveSettings()\n        tabs.forEach { $0.applyContentBlocking(adBlocking: settings.adBlockingEnabled, trackerBlocking: settings.trackerBlockingEnabled) }\n    }\n\n    func updateCustomStartPage(_ value: String) {\n        settings.customStartPageURL = value\n        saveSettings()\n    }\n\n    var resolvedStartPageURL: URL? {\n        guard settings.startPage == "custom" else { return nil }\n        let value = settings.customStartPageURL.trimmingCharacters(in: .whitespacesAndNewlines)\n        guard !value.isEmpty else { return nil }\n        if let url = URL(string: value), ["http", "https"].contains(url.scheme?.lowercased() ?? "") { return url }\n        return URL(string: "https://" + value)\n    }\n\n    private func saveSettings() {\n        guard let data = try? JSONEncoder().encode(settings) else { return }\n        UserDefaults.standard.set(data, forKey: settingsKey)\n    }\n\n    private func makeTab(id: UUID = UUID(), spaceID: String, isPrivate: Bool = false) -> BrowserTab {
        let tab = BrowserTab(id: id, spaceID: spaceID, isPrivate: isPrivate)\n        tab.applyContentBlocking(adBlocking: settings.adBlockingEnabled, trackerBlocking: settings.trackerBlockingEnabled)
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
            SavedBrowserTab(id: $0.id, spaceID: $0.spaceID, address: $0.address)
        }
        let safeActiveTabID = activeTab?.isPrivate == false ? activeTabID : tabs.last(where: { !$0.isPrivate && $0.spaceID == activeSpaceID })?.id
        let session = SavedBrowserSession(tabs: savedTabs, activeTabID: safeActiveTabID, activeSpaceID: activeSpaceID)
        guard let data = try? JSONEncoder().encode(session) else { return }
        UserDefaults.standard.set(data, forKey: sessionKey)
    }
}
