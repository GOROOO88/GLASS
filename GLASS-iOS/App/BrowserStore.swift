import Foundation
import Combine

struct BrowserBookmark: Codable, Identifiable, Equatable {
    var id: String { url }
    let title: String
    let url: String
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

@MainActor
final class BrowserStore: ObservableObject {
    @Published private(set) var tabs: [BrowserTab] = []
    @Published var activeTabID: UUID?
    @Published private(set) var history: [String] = []
    @Published private(set) var bookmarks: [BrowserBookmark] = []
    @Published private(set) var spaces: [BrowserSpace] = []
    @Published var activeSpaceID = "personal"

    private let historyKey = "glass.ios.history.v1"
    private let bookmarksKey = "glass.ios.bookmarks.v1"
    private let spacesKey = "glass.ios.spaces.v1"
    private let sessionKey = "glass.ios.session.v1"

    init() {
        let defaults = UserDefaults.standard
        history = defaults.stringArray(forKey: historyKey) ?? []
        if let data = defaults.data(forKey: bookmarksKey),
           let saved = try? JSONDecoder().decode([BrowserBookmark].self, from: data) {
            bookmarks = saved
        }
        if let data = defaults.data(forKey: spacesKey),
           let saved = try? JSONDecoder().decode([BrowserSpace].self, from: data), !saved.isEmpty {
            spaces = saved
        } else {
            spaces = BrowserSpace.defaults
        }

        var restoredTabs: [SavedBrowserTab] = []
        if let data = defaults.data(forKey: sessionKey) {
            restoredTabs = (try? JSONDecoder().decode([SavedBrowserTab].self, from: data)) ?? []
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
            activeTabID = tabs.first?.id
            activeSpaceID = activeTab?.spaceID ?? "personal"
        }
        saveSpaces()
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

    func addTab(spaceID: String? = nil) {
        let destination = spaceID ?? activeSpaceID
        let tab = makeTab(spaceID: destination)
        tabs.append(tab)
        activeSpaceID = destination
        activeTabID = tab.id
        saveSession()
    }

    func selectSpace(_ space: BrowserSpace) {
        activeSpaceID = space.id
        if let existing = tabs.last(where: { $0.spaceID == space.id }) {
            activeTabID = existing.id
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
            if let tab = tabs.last(where: { $0.spaceID == "personal" }) {
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
    }

    func close(_ tab: BrowserTab) {
        guard let index = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        let wasActive = activeTabID == tab.id
        let oldSpaceID = tab.spaceID
        tabs.remove(at: index)

        if tabs.isEmpty {
            addTab(spaceID: oldSpaceID)
        } else if wasActive {
            activeTabID = tabs.last(where: { $0.spaceID == oldSpaceID })?.id ?? tabs.first?.id
            activeSpaceID = activeTab?.spaceID ?? "personal"
        }
        saveSession()
    }

    private func makeTab(id: UUID = UUID(), spaceID: String) -> BrowserTab {
        let tab = BrowserTab(id: id, spaceID: spaceID)
        tab.onVisit = { [weak self] url, title in
            self?.recordVisit(url, title: title)
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

    private func saveBookmarks() {
        guard let data = try? JSONEncoder().encode(bookmarks) else { return }
        UserDefaults.standard.set(data, forKey: bookmarksKey)
    }

    private func saveSpaces() {
        guard let data = try? JSONEncoder().encode(spaces) else { return }
        UserDefaults.standard.set(data, forKey: spacesKey)
    }

    private func saveSession() {
        let saved = tabs.map { SavedBrowserTab(id: $0.id, spaceID: $0.spaceID, address: $0.address) }
        guard let data = try? JSONEncoder().encode(saved) else { return }
        UserDefaults.standard.set(data, forKey: sessionKey)
    }
}
