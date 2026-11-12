import Foundation
import Combine

struct BrowserBookmark: Codable, Identifiable, Equatable {
    var id: String { url }
    let title: String
    let url: String
}

@MainActor
final class BrowserStore: ObservableObject {
    @Published private(set) var tabs: [BrowserTab] = []
    @Published var activeTabID: UUID?
    @Published private(set) var history: [String] = []
    @Published private(set) var bookmarks: [BrowserBookmark] = []

    private let historyKey = "glass.ios.history.v1"
    private let bookmarksKey = "glass.ios.bookmarks.v1"

    init() {
        history = UserDefaults.standard.stringArray(forKey: historyKey) ?? []
        if let data = UserDefaults.standard.data(forKey: bookmarksKey),
           let saved = try? JSONDecoder().decode([BrowserBookmark].self, from: data) {
            bookmarks = saved
        }
        addTab()
    }

    var activeTab: BrowserTab? {
        tabs.first(where: { $0.id == activeTabID })
    }

    func addTab() {
        let tab = BrowserTab()
        tab.onVisit = { [weak self] url, title in
            self?.recordVisit(url, title: title)
        }
        tabs.append(tab)
        activeTabID = tab.id
    }

    func select(_ tab: BrowserTab) {
        activeTabID = tab.id
    }

    func close(_ tab: BrowserTab) {
        guard let index = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        let wasActive = activeTabID == tab.id
        tabs.remove(at: index)

        if tabs.isEmpty {
            addTab()
        } else if wasActive {
            activeTabID = tabs[min(index, tabs.count - 1)].id
        }
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
}
