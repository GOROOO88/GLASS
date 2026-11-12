import SwiftUI

@main
struct GLASSApp: App {
    @StateObject private var browser = BrowserStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(browser)
                .preferredColorScheme(.dark)
        }
    }
}
