import Foundation
import Combine

@MainActor
final class BrowserStore: ObservableObject {
    @Published private(set) var tabs: [BrowserTab] = []
    @Published var activeTabID: UUID?

    @Published private(set) var history: [String] = []

    private let historyKey = "glass.ios.history.v1"

    init() {
        history = UserDefaults.standard.stringArray(forKey: historyKey) ?? []
        addTab()
    }

    var activeTab: BrowserTab? {
        tabs.first(where: { $0.id == activeTabID })
    }

    func addTab() {
        let tab = BrowserTab()
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

    func recordVisit(_ url: URL) {
        let value = url.absoluteString
        history.removeAll(where: { $0 == value })
        history.insert(value, at: 0)
        if history.count > 500 {
            history = Array(history.prefix(500))
        }
        UserDefaults.standard.set(history, forKey: historyKey)
    }
}
