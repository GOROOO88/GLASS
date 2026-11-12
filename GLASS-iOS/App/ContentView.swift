import SwiftUI

private enum GlassPalette {
    static let background = Color(red: 0.055, green: 0.05, blue: 0.085)
    static let panel = Color.white.opacity(0.075)
    static let line = Color.white.opacity(0.11)
    static let accent = Color(red: 0.68, green: 0.53, blue: 1.0)
    static let secondary = Color.white.opacity(0.58)
}

struct ContentView: View {
    @EnvironmentObject private var browser: BrowserStore
    @State private var addressText = ""

    var body: some View {
        ZStack {
            GlassPalette.background.ignoresSafeArea()
            RadialGradient(colors: [GlassPalette.accent.opacity(0.18), .clear], center: .top, startRadius: 8, endRadius: 420)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                header
                addressBar
                tabStrip

                Group {
                    if let tab = browser.activeTab {
                        if tab.address.isEmpty {
                            startPage
                        } else {
                            BrowserView(tab: tab)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        }
                    } else {
                        startPage
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                navigationBar
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .onChange(of: browser.activeTabID) { _, _ in
            addressText = browser.activeTab?.address ?? ""
        }
        .onChange(of: browser.activeTab?.address) { _, value in
            if let value { addressText = value }
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "circle.hexagongrid.fill")
                    .foregroundStyle(GlassPalette.accent)
                Text("GLASS")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .tracking(2.4)
            }
            Spacer()
            Button {} label: {
                Image(systemName: "sparkle")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(GlassPalette.panel, in: Circle())
                    .overlay(Circle().stroke(GlassPalette.line))
            }
            .accessibilityLabel("AI assistant")
        }
    }

    private var addressBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(GlassPalette.secondary)
            TextField("Search or enter address", text: $addressText)
                .font(.system(size: 15))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .submitLabel(.go)
                .onSubmit(openAddress)
            if let tab = browser.activeTab, tab.isLoading {
                ProgressView().tint(GlassPalette.accent)
            } else {
                Button(action: openAddress) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(GlassPalette.accent)
                }
                .accessibilityLabel("Open address")
            }
        }
        .padding(.horizontal, 15)
        .frame(height: 52)
        .background(GlassPalette.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(GlassPalette.line))
    }

    private var tabStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(browser.tabs) { tab in
                    HStack(spacing: 7) {
                        Button {
                            browser.select(tab)
                        } label: {
                            Text(tab.title)
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                                .foregroundStyle(browser.activeTabID == tab.id ? .white : GlassPalette.secondary)
                        }
                        Button {
                            browser.close(tab)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(GlassPalette.secondary)
                        }
                        .accessibilityLabel("Close tab")
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(browser.activeTabID == tab.id ? GlassPalette.accent.opacity(0.24) : GlassPalette.panel,
                                in: Capsule())
                    .overlay(Capsule().stroke(browser.activeTabID == tab.id ? GlassPalette.accent.opacity(0.45) : GlassPalette.line))
                }
                Button(action: browser.addTab) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(GlassPalette.panel, in: Circle())
                        .overlay(Circle().stroke(GlassPalette.line))
                }
                .accessibilityLabel("New tab")
            }
        }
    }

    private var startPage: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(GlassPalette.accent)
                .shadow(color: GlassPalette.accent.opacity(0.55), radius: 24)
            Text("GLASS")
                .font(.system(size: 31, weight: .bold, design: .rounded))
                .tracking(7)
                .foregroundStyle(.white)
            Text("A clearer way to browse.")
                .font(.system(size: 14))
                .foregroundStyle(GlassPalette.secondary)
            Button {
                addressText = "https://www.google.com"
                openAddress()
            } label: {
                Label("Start browsing", systemImage: "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(GlassPalette.accent.opacity(0.28), in: Capsule())
                    .overlay(Capsule().stroke(GlassPalette.accent.opacity(0.45)))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var navigationBar: some View {
        HStack(spacing: 0) {
            navigationButton("chevron.left", enabled: browser.activeTab?.canGoBack == true) {
                browser.activeTab?.goBack()
            }
            Spacer()
            navigationButton("chevron.right", enabled: browser.activeTab?.canGoForward == true) {
                browser.activeTab?.goForward()
            }
            Spacer()
            navigationButton("arrow.clockwise", enabled: browser.activeTab?.address.isEmpty == false) {
                browser.activeTab?.reload()
            }
            Spacer()
            navigationButton("square.on.square", enabled: true) {
                browser.addTab()
            }
            Text("\(browser.tabs.count)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(GlassPalette.secondary)
                .padding(.leading, 4)
        }
        .padding(.horizontal, 18)
        .frame(height: 48)
        .background(GlassPalette.panel, in: Capsule())
        .overlay(Capsule().stroke(GlassPalette.line))
    }

    private func navigationButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(enabled ? .white : GlassPalette.secondary.opacity(0.3))
                .frame(width: 38, height: 38)
        }
        .disabled(!enabled)
    }

    private func openAddress() {
        let input = addressText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty, let tab = browser.activeTab else { return }

        let destination: URL?
        if let candidate = URL(string: input), let scheme = candidate.scheme,
           ["http", "https"].contains(scheme.lowercased()) {
            destination = candidate
        } else if input.contains(".") && !input.contains(" ") {
            destination = URL(string: "https://" + input)
        } else {
            let query = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? input
            destination = URL(string: "https://www.google.com/search?q=" + query)
        }

        guard let destination else { return }
        tab.load(destination)
        browser.recordVisit(destination)
        hideKeyboard()
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
