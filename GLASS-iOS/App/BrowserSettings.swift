import Foundation

enum GlassSearchEngine: String, CaseIterable, Codable, Identifiable {
    case google, bing, duckDuckGo, brave, yahoo

    var id: String { rawValue }
    var title: String {
        switch self {
        case .google: return "Google"
        case .bing: return "Bing"
        case .duckDuckGo: return "DuckDuckGo"
        case .brave: return "Brave Search"
        case .yahoo: return "Yahoo"
        }
    }

    func searchURL(for query: String) -> URL? {
        var components: URLComponents?
        switch self {
        case .google: components = URLComponents(string: "https://www.google.com/search")
        case .bing: components = URLComponents(string: "https://www.bing.com/search")
        case .duckDuckGo: components = URLComponents(string: "https://duckduckgo.com/")
        case .brave: components = URLComponents(string: "https://search.brave.com/search")
        case .yahoo: components = URLComponents(string: "https://search.yahoo.com/search")
        }
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        return components?.url
    }
}

struct BrowserSitePermission: Codable, Identifiable, Equatable {
    var id: String { domain }
    let domain: String
    var cameraAllowed: Bool
    var microphoneAllowed: Bool
}

struct GlassBrowserSettings: Codable, Equatable {
    var searchEngine: GlassSearchEngine = .google
    var adBlockingEnabled = true
    var trackerBlockingEnabled = true
    var cameraAllowed = true
    var microphoneAllowed = true
    var startPage = "glass"
    var customStartPageURL = ""
    var clearPrivateDataOnClose = true
    var cloudSyncEnabled = false
    var sitePermissions: [String: BrowserSitePermission] = [:]
}
