import SwiftUI
import UIKit

private enum GlassPalette {
    static let background = Color(red: 0.035, green: 0.035, blue: 0.065)
    static let line = Color.white.opacity(0.12)
    static let secondary = Color.white.opacity(0.58)
}

struct ContentView: View {
    @EnvironmentObject private var browser: BrowserStore
    @AppStorage("glass.theme.preset") private var themePreset = "violet"
    @AppStorage("glass.theme.panelOpacity") private var themePanelOpacity = 0.075
    @AppStorage("glass.theme.glow") private var themeGlow = 0.55
    @AppStorage("glass.theme.cornerRadius") private var themeCornerRadius = 20.0
    @AppStorage("glass.theme.blur") private var themeBlur = 0.65
    @AppStorage("glass.theme.backgroundStyle") private var themeBackgroundStyle = "aurora"
    @AppStorage("glass.theme.addressOpacity") private var themeAddressOpacity = 0.075
    @AppStorage("glass.theme.cardOpacity") private var themeCardOpacity = 0.075
    @AppStorage("glass.theme.dockOpacity") private var themeDockOpacity = 0.052
    @AppStorage("glass.theme.iconStyle") private var themeIconStyle = "soft"
    @AppStorage("glass.theme.motion") private var themeMotion = 0.65
    @State private var addressText = ""
    @State private var showLibrary = false
    @State private var librarySection = 0
    @State private var showSpaces = false
    @State private var showTabs = false
    @State private var newSpaceName = ""
    @State private var showPrivacy = false
    @State private var showSettings = false
    @State private var confirmClearWebsiteData = false
    @State private var privacyActionMessage = ""

    var body: some View {
        ZStack {
            Group {
                switch themeBackgroundStyle {
                case "deep":
                    GlassPalette.background
                case "gradient":
                    LinearGradient(
                        colors: GlassAppearance.previewColors(for: themePreset).map { $0.opacity(0.52) } + [GlassPalette.background],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                default:
                    ZStack {
                        GlassPalette.background
                        RadialGradient(
                            colors: [GlassAppearance.accent(for: themePreset).opacity(0.25), .clear],
                            center: .top,
                            startRadius: 8,
                            endRadius: 460
                        )
                        RadialGradient(
                            colors: [GlassAppearance.previewColors(for: themePreset)[2].opacity(0.10), .clear],
                            center: .bottomTrailing,
                            startRadius: 5,
                            endRadius: 300
                        )
                    }
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 12) {
                header
                addressBar
                spacesBar
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
            .padding(.bottom, 12)
        }
        .animation(.easeInOut(duration: 0.08 + themeMotion * 0.42), value: themePreset)
        .onChange(of: browser.activeTabID) { _, _ in
            addressText = browser.activeTab?.address ?? ""
        }
        .onChange(of: browser.activeTab?.address) { _, value in
            if let value { addressText = value }
        }
        .sheet(isPresented: $showLibrary) {
            librarySheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showSpaces) {
            spacesSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showTabs) {
            tabsSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showSettings) {
            BrowserSettingsView()
                .environmentObject(browser)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPrivacy) {
            privacySheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.dark)
        }
        .alert("Clear website data?", isPresented: $confirmClearWebsiteData) {
            Button("Cancel", role: .cancel) {}
            Button("Clear data", role: .destructive) {
                browser.clearWebsiteData {
                    privacyActionMessage = "Cookies, cache and website storage were cleared."
                }
            }
        } message: {
            Text("This signs you out of many websites and removes locally stored site data. Bookmarks and downloaded files stay untouched.")
        }
        .alert("Privacy", isPresented: Binding(
            get: { !privacyActionMessage.isEmpty },
            set: { if !$0 { privacyActionMessage = "" } }
        )) {
            Button("OK") { privacyActionMessage = "" }
        } message: {
            Text(privacyActionMessage)
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "circle.hexagongrid.fill").foregroundStyle(GlassAppearance.accent(for: themePreset))
                Text("GLASS").font(.system(size: 17, weight: .bold, design: .rounded)).tracking(2.4)
            }
            Spacer()
            Button {
                librarySection = 1
                showLibrary = true
            } label: {
                Image(systemName: "books.vertical").font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white).frame(width: 42, height: 42)
                    .background(Color.white.opacity(themePanelOpacity), in: Circle()).overlay(Circle().stroke(GlassPalette.line))
            }
            .accessibilityLabel("Library")
            Button {
                librarySection = 2
                showLibrary = true
            } label: {
                Image(systemName: "arrow.down.circle").font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white).frame(width: 42, height: 42)
                    .background(Color.white.opacity(themePanelOpacity), in: Circle()).overlay(Circle().stroke(GlassPalette.line))
            }
            .accessibilityLabel("Downloads")
            Button {
                showSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3").font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white).frame(width: 42, height: 42)
                    .background(Color.white.opacity(themePanelOpacity), in: Circle()).overlay(Circle().stroke(GlassPalette.line))
            }
            .accessibilityLabel("Browser settings")
            Button {
                showPrivacy = true
            } label: {
                Image(systemName: "hand.raised").font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white).frame(width: 42, height: 42)
                    .background(Color.white.opacity(themePanelOpacity), in: Circle()).overlay(Circle().stroke(GlassPalette.line))
            }
            .accessibilityLabel("Privacy settings")
        }
    }

    private var addressBar: some View {
        HStack(spacing: 10) {
            if browser.activeTab?.isPrivate == true {
                Image(systemName: "eye.slash.fill").foregroundStyle(GlassAppearance.accent(for: themePreset))
            } else {
                Image(systemName: "magnifyingglass").foregroundStyle(GlassPalette.secondary)
            }
            TextField(browser.activeTab?.isPrivate == true ? "Private browsing" : "Search or enter address", text: $addressText)
                .font(.system(size: 15)).textInputAutocapitalization(.never)
                .autocorrectionDisabled().keyboardType(.URL).submitLabel(.go).onSubmit(openAddress)
            if let tab = browser.activeTab, tab.isLoading {
                ProgressView().tint(GlassAppearance.accent(for: themePreset))
            } else {
                Button(action: openAddress) {
                    Image(systemName: "arrow.up.right").font(.system(size: 14, weight: .bold)).foregroundStyle(GlassAppearance.accent(for: themePreset))
                }
                .accessibilityLabel("Open address")
            }
            if let tab = browser.activeTab, !tab.isPrivate, !tab.address.isEmpty {
                Button {
                    browser.toggleBookmark(url: tab.address, title: tab.title)
                } label: {
                    Image(systemName: browser.isBookmarked(tab.address) ? "star.fill" : "star")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(GlassAppearance.accent(for: themePreset))
                }
                .accessibilityLabel(browser.isBookmarked(tab.address) ? "Remove bookmark" : "Add bookmark")
            }
        }
        .padding(.horizontal, 15).frame(height: 54)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: themeCornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: themeCornerRadius).fill(Color.white.opacity(themeAddressOpacity)))
        .overlay(RoundedRectangle(cornerRadius: themeCornerRadius).stroke(Color.white.opacity(0.15)))
        .shadow(color: GlassAppearance.accent(for: themePreset).opacity(themeGlow * 0.12), radius: 16, y: 5)
    }

    private var spacesBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(browser.spaces) { space in
                    Button {
                        browser.selectSpace(space)
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: space.symbol)
                            Text(space.name).lineLimit(1)
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(browser.activeSpaceID == space.id ? .white : GlassPalette.secondary)
                        .padding(.horizontal, 13).frame(height: 34)
                        .background(browser.activeSpaceID == space.id ? spaceColor(space.tint).opacity(0.30) : Color.white.opacity(themePanelOpacity), in: Capsule())
                        .overlay(Capsule().stroke(browser.activeSpaceID == space.id ? spaceColor(space.tint).opacity(0.75) : GlassPalette.line))
                    }
                }
                Button {
                    showSpaces = true
                } label: {
                    Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white).frame(width: 34, height: 34)
                        .background(Color.white.opacity(themePanelOpacity), in: Circle()).overlay(Circle().stroke(GlassPalette.line))
                }
                .accessibilityLabel("Manage spaces")
            }
        }
    }

    private var tabStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(browser.visibleTabs) { tab in
                    HStack(spacing: 7) {
                        Button { browser.select(tab) } label: {
                            HStack(spacing: 5) {
                                if tab.isPrivate {
                                    Image(systemName: "eye.slash.fill").font(.system(size: 9))
                                }
                                Text(tab.title).font(.system(size: 12, weight: .medium)).lineLimit(1)
                            }
                            .foregroundStyle(browser.activeTabID == tab.id ? .white : GlassPalette.secondary)
                        }
                        Button { browser.close(tab) } label: {
                            Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).foregroundStyle(GlassPalette.secondary)
                        }
                        .accessibilityLabel("Close tab")
                    }
                    .padding(.horizontal, 12).frame(height: 36)
                    .background(tab.isPrivate ? GlassAppearance.accent(for: themePreset).opacity(0.20) : (browser.activeTabID == tab.id ? GlassAppearance.accent(for: themePreset).opacity(0.24) : Color.white.opacity(themePanelOpacity)), in: Capsule())
                    .overlay(Capsule().stroke(browser.activeTabID == tab.id ? GlassAppearance.accent(for: themePreset).opacity(0.45) : GlassPalette.line))
                    .contextMenu {
                        ForEach(browser.spaces.filter { $0.id != tab.spaceID }) { destination in
                            Button {
                                browser.move(tab, to: destination)
                            } label: {
                                Label("Move to \(destination.name)", systemImage: destination.symbol)
                            }
                        }
                    }
                }
                Button { browser.addTab() } label: {
                    Image(systemName: "plus").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                        .frame(width: 36, height: 36).background(Color.white.opacity(themePanelOpacity), in: Circle()).overlay(Circle().stroke(GlassPalette.line))
                }
                .accessibilityLabel("New tab")
            }
        }
    }

    private var startPage: some View {
        Group {
            if browser.activeTab?.isPrivate == true {
                VStack(spacing: 14) {
                    Spacer()
                    Image(systemName: "eye.slash.circle.fill")
                        .font(.system(size: 46, weight: .light))
                        .foregroundStyle(GlassAppearance.accent(for: themePreset))
                        .shadow(color: GlassAppearance.accent(for: themePreset).opacity(themeGlow), radius: 24)
                    Text("PRIVATE SPACE")
                        .font(.system(size: 23, weight: .bold, design: .rounded)).tracking(3)
                        .foregroundStyle(.white)
                    Text("This session stays on this device and is not saved.")
                        .font(.system(size: 13)).foregroundStyle(GlassPalette.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 9) {
                                Image(systemName: "circle.hexagongrid.fill")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(GlassAppearance.accent(for: themePreset))
                                Text("GLASS")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .tracking(3).foregroundStyle(.white.opacity(0.8))
                                Spacer()
                                Text("YOUR SPACE")
                                    .font(.system(size: 9, weight: .bold)).tracking(1.6)
                                    .foregroundStyle(GlassPalette.secondary)
                            }
                            Text("A quieter corner\nof the web.")
                                .font(.system(size: 34, weight: .semibold, design: .rounded))
                                .tracking(-0.8).foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Everything you need, right where you left it.")
                                .font(.system(size: 13)).foregroundStyle(GlassPalette.secondary)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            LinearGradient(
                                colors: [
                                    GlassAppearance.accent(for: themePreset).opacity(0.23),
                                    Color.white.opacity(0.035),
                                    Color.white.opacity(0.015)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: themeCornerRadius + 8, style: .continuous)
                        )
                        .overlay(RoundedRectangle(cornerRadius: themeCornerRadius + 8).stroke(Color.white.opacity(0.13)))

                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeading("QUICK ACCESS", subtitle: "Your everyday destinations")
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                quickLink("YouTube", subtitle: "Watch", symbol: "play.rectangle.fill", url: "https://www.youtube.com")
                                quickLink("Spotify", subtitle: "Listen", symbol: "waveform", url: "https://open.spotify.com")
                                quickLink("Reddit", subtitle: "Explore", symbol: "bubble.left.and.bubble.right.fill", url: "https://www.reddit.com")
                                quickLink("Wikipedia", subtitle: "Discover", symbol: "book.closed.fill", url: "https://www.wikipedia.org")
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeading("SPACES", subtitle: "Keep different parts of life separate")
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(browser.spaces) { space in
                                    Button {
                                        browser.selectSpace(space)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 9) {
                                            HStack(alignment: .top, spacing: 10) {
                                                Image(systemName: space.symbol)
                                                    .font(.system(size: 17, weight: .semibold))
                                                    .foregroundStyle(spaceColor(space.tint))
                                                    .frame(width: 36, height: 36)
                                                    .background(spaceColor(space.tint).opacity(0.16), in: RoundedRectangle(cornerRadius: 12))
                                                Spacer(minLength: 0)
                                                Image(systemName: browser.activeSpaceID == space.id ? "checkmark.circle.fill" : "arrow.up.right")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundStyle(browser.activeSpaceID == space.id ? GlassAppearance.accent(for: themePreset) : GlassPalette.secondary)
                                            }
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(space.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                                                Text(browser.activeSpaceID == space.id ? "Currently active" : "Open space")
                                                    .font(.system(size: 10)).foregroundStyle(GlassPalette.secondary)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                    .padding(13)
                                    .background(.ultraThinMaterial.opacity(themeBlur), in: RoundedRectangle(cornerRadius: themeCornerRadius, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: themeCornerRadius, style: .continuous).fill(Color.white.opacity(themeCardOpacity)))
                                    .overlay(RoundedRectangle(cornerRadius: themeCornerRadius).stroke(GlassPalette.line))
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                sectionHeading("RECENTLY VISITED", subtitle: "Pick up where you left off")
                                Spacer()
                                Button("History") { librarySection = 0; showLibrary = true }
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(GlassAppearance.accent(for: themePreset))
                            }
                            if browser.history.isEmpty {
                                HStack(spacing: 10) {
                                    Image(systemName: "clock").foregroundStyle(GlassPalette.secondary)
                                    Text("Your recent pages will appear here.")
                                        .font(.system(size: 12)).foregroundStyle(GlassPalette.secondary)
                                }
                                .padding(15).frame(maxWidth: .infinity, alignment: .leading)
                                .background(.ultraThinMaterial.opacity(themeBlur), in: RoundedRectangle(cornerRadius: themeCornerRadius))
                                .overlay(RoundedRectangle(cornerRadius: themeCornerRadius).fill(Color.white.opacity(themeCardOpacity)))
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(Array(browser.history.prefix(5)), id: \.self) { value in
                                        Button { openLibraryURL(value) } label: {
                                            HStack(spacing: 11) {
                                                Image(systemName: "globe")
                                                    .font(.system(size: 14)).foregroundStyle(GlassAppearance.accent(for: themePreset))
                                                    .frame(width: 30, height: 30)
                                                    .background(GlassAppearance.accent(for: themePreset).opacity(0.13), in: Circle())
                                                VStack(alignment: .leading, spacing: 3) {
                                                    Text(URL(string: value)?.host ?? value)
                                                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                                                    Text(value).font(.system(size: 10)).foregroundStyle(GlassPalette.secondary).lineLimit(1)
                                                }
                                                Spacer()
                                                Image(systemName: "arrow.up.right").font(.system(size: 10)).foregroundStyle(GlassPalette.secondary)
                                            }
                                            .padding(.vertical, 10).padding(.horizontal, 12)
                                        }
                                        .buttonStyle(.plain)
                                        if value != browser.history.prefix(5).last {
                                            Divider().overlay(Color.white.opacity(0.07)).padding(.leading, 52)
                                        }
                                    }
                                }
                                .background(Color.white.opacity(themeCardOpacity), in: RoundedRectangle(cornerRadius: themeCornerRadius))
                                .overlay(RoundedRectangle(cornerRadius: themeCornerRadius).stroke(GlassPalette.line))
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private func sectionHeading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.system(size: 10, weight: .bold)).tracking(1.5).foregroundStyle(GlassPalette.secondary)
            Text(subtitle).font(.system(size: 12)).foregroundStyle(.white.opacity(0.78))
        }
    }

    private func quickLink(_ title: String, subtitle: String, symbol: String, url: String) -> some View {
        Button { openLibraryURL(url) } label: {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(GlassAppearance.accent(for: themePreset))
                    .frame(width: 34, height: 34)
                    .background(GlassAppearance.accent(for: themePreset).opacity(0.14), in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                    Text(subtitle).font(.system(size: 10)).foregroundStyle(GlassPalette.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right").font(.system(size: 9, weight: .semibold)).foregroundStyle(GlassPalette.secondary)
            }
            .padding(12)
            .background(.ultraThinMaterial.opacity(themeBlur), in: RoundedRectangle(cornerRadius: themeCornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: themeCornerRadius).fill(Color.white.opacity(themePanelOpacity)))
            .overlay(RoundedRectangle(cornerRadius: themeCornerRadius).stroke(Color.white.opacity(0.11)))
        }
        .buttonStyle(.plain)
    }

    private var navigationBar: some View {
        HStack(spacing: 0) {
            dockButton("chevron.left", title: "Back", enabled: browser.activeTab?.canGoBack == true) {
                browser.activeTab?.goBack()
            }
            Spacer(minLength: 2)
            dockButton("chevron.right", title: "Forward", enabled: browser.activeTab?.canGoForward == true) {
                browser.activeTab?.goForward()
            }
            Spacer(minLength: 2)
            dockButton("books.vertical", title: "Library", enabled: true) {
                librarySection = 1
                showLibrary = true
            }
            Spacer(minLength: 2)
            dockButton("clock.arrow.circlepath", title: "History", enabled: true) {
                librarySection = 0
                showLibrary = true
            }
            Spacer(minLength: 2)
            dockButton("square.on.square", title: "Tabs", enabled: true) {
                showTabs = true
            }
            Spacer(minLength: 2)
            Button {
                browser.addTab()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(GlassAppearance.accent(for: themePreset), in: Circle())
                    .shadow(color: GlassAppearance.accent(for: themePreset).opacity(themeGlow), radius: 12, y: 3)
            }
            .accessibilityLabel("New tab")
        }
        .padding(.horizontal, 13)
        .frame(height: 62)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().fill(Color.white.opacity(themeDockOpacity)))
        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
        .shadow(color: .black.opacity(0.24), radius: 18, y: 7)
        .padding(.horizontal, 2)
    }

    private func dockButton(_ symbol: String, title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: themeIconStyle == "bold" ? .bold : .medium))
                Text(title)
                    .font(.system(size: 8, weight: .medium))
            }
            .foregroundStyle(enabled ? .white : GlassPalette.secondary.opacity(0.32))
            .frame(minWidth: 37, minHeight: 46)
            .contentShape(Rectangle())
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }

    private var librarySheet: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Picker("Library", selection: $librarySection) {
                    Text("History").tag(0)
                    Text("Bookmarks").tag(1)
                    Text("Downloads").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(5)
                .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .padding(.horizontal, 16)
                if librarySection == 0 {
                    if browser.history.isEmpty {
                        ContentUnavailableView("No history yet", systemImage: "clock", description: Text("Pages you visit will appear here."))
                    } else {
                        List {
                            ForEach(browser.history, id: \.self) { url in
                                libraryRow(title: URL(string: url)?.host ?? url, subtitle: url, symbol: "clock") { openLibraryURL(url) }
                            }
                        }.listStyle(.plain).scrollContentBackground(.hidden)
                    }
                } else if librarySection == 1 {
                    if browser.bookmarks.isEmpty {
                        ContentUnavailableView("No bookmarks yet", systemImage: "star", description: Text("Save a page with the star in the address bar."))
                    } else {
                        List {
                            ForEach(browser.bookmarks) { bookmark in
                                libraryRow(title: bookmark.title, subtitle: bookmark.url, symbol: "star") { openLibraryURL(bookmark.url) }
                                    .swipeActions {
                                        Button(role: .destructive) { browser.removeBookmark(bookmark) } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }.listStyle(.plain).scrollContentBackground(.hidden)
                    }
                } else {
                    if browser.downloads.isEmpty && browser.activeDownloads.isEmpty {
                        ContentUnavailableView("No downloads yet", systemImage: "arrow.down.circle", description: Text("Files you download from websites will appear here."))
                    } else {
                        List {
                            ForEach(browser.activeDownloads) { download in
                                HStack(spacing: 10) {
                                    Image(systemName: download.failure == nil ? "arrow.down.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundStyle(download.failure == nil ? GlassAppearance.accent(for: themePreset) : .orange)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(download.filename).font(.system(size: 13, weight: .medium)).foregroundStyle(.white).lineLimit(1)
                                        if let failure = download.failure {
                                            Text(failure).font(.system(size: 10)).foregroundStyle(.orange).lineLimit(2)
                                        } else {
                                            ProgressView(value: download.progress).tint(GlassAppearance.accent(for: themePreset))
                                            Text("\(Int(download.progress * 100))%")
                                                .font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(GlassPalette.secondary)
                                        }
                                    }
                                    Spacer()
                                    if download.failure != nil {
                                        Button { browser.retryDownload(download) } label: {
                                            Image(systemName: "arrow.clockwise").foregroundStyle(GlassAppearance.accent(for: themePreset))
                                        }
                                        .accessibilityLabel("Retry download")
                                    } else {
                                        Button(role: .destructive) { browser.cancelDownload(download) } label: {
                                            Image(systemName: "xmark.circle.fill").foregroundStyle(.orange)
                                        }
                                        .accessibilityLabel("Cancel download")
                                    }
                                }
                                .listRowBackground(Color.white.opacity(themePanelOpacity))
                            }
                            ForEach(browser.downloads) { download in
                                HStack(spacing: 10) {
                                    Image(systemName: "doc.fill").foregroundStyle(GlassAppearance.accent(for: themePreset)).frame(width: 28)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(download.filename).font(.system(size: 13, weight: .medium)).foregroundStyle(.white).lineLimit(1)
                                        Text(download.completedAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.system(size: 10)).foregroundStyle(GlassPalette.secondary)
                                    }
                                    Spacer()
                                    ShareLink(item: download.fileURL) {
                                        Image(systemName: "square.and.arrow.up").foregroundStyle(GlassAppearance.accent(for: themePreset))
                                    }
                                }
                                .listRowBackground(Color.white.opacity(themePanelOpacity))
                                .swipeActions {
                                    Button(role: .destructive) { browser.removeDownload(download) } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }.listStyle(.plain).scrollContentBackground(.hidden)
                    }
                }
            }
            .padding(.top, 12).background(GlassPalette.background.ignoresSafeArea())
            .navigationTitle("Library").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if librarySection == 0 && !browser.history.isEmpty {
                        Button("Clear") { browser.clearHistory() }
                    } else if librarySection == 2 && !browser.downloads.isEmpty {
                        Button("Clear") { browser.clearDownloads() }
                    }
                }
                ToolbarItem(placement: .topBarLeading) { Button("Done") { showLibrary = false } }
            }
        }
        .tint(GlassAppearance.accent(for: themePreset))
        .preferredColorScheme(.dark)
    }

    private var privacySheet: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "eye.slash.circle.fill").font(.system(size: 24)).foregroundStyle(GlassAppearance.accent(for: themePreset))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Private tabs").foregroundStyle(.white)
                            Text("Use a separate temporary website store. Private tabs are not restored after closing GLASS.")
                                .font(.system(size: 12)).foregroundStyle(GlassPalette.secondary)
                        }
                    }
                    .listRowBackground(Color.white.opacity(themePanelOpacity))
                    HStack(spacing: 12) {
                        Image(systemName: "clock.badge.xmark").font(.system(size: 22)).foregroundStyle(GlassAppearance.accent(for: themePreset))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Browsing history").foregroundStyle(.white)
                            Text("Regular tabs save visited addresses on this device. Private tabs do not.")
                                .font(.system(size: 12)).foregroundStyle(GlassPalette.secondary)
                        }
                    }
                    .listRowBackground(Color.white.opacity(themePanelOpacity))
                } header: {
                    Text("On-device privacy")
                }
                Section {
                    Button(role: .destructive) {
                        confirmClearWebsiteData = true
                    } label: {
                        Label("Clear cookies, cache and site data", systemImage: "trash")
                    }
                    .listRowBackground(Color.white.opacity(themePanelOpacity))
                    Button(role: .destructive) {
                        browser.clearHistory()
                        privacyActionMessage = "Browsing history was cleared."
                    } label: {
                        Label("Clear browsing history", systemImage: "clock")
                    }
                    .listRowBackground(Color.white.opacity(themePanelOpacity))
                } header: {
                    Text("Clear data")
                } footer: {
                    Text("Clearing website data may sign you out of websites. Bookmarks and downloaded files are not deleted.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(GlassPalette.background)
            .navigationTitle("Privacy").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { showPrivacy = false } }
            }
        }
        .tint(GlassAppearance.accent(for: themePreset))
        .preferredColorScheme(.dark)
    }

    private var tabsSheet: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("YOUR TABS")
                                .font(.system(size: 10, weight: .bold)).tracking(1.6)
                                .foregroundStyle(GlassPalette.secondary)
                            Text("\(browser.visibleTabs.count) open")
                                .font(.system(size: 23, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Button {
                            browser.addTab()
                            showTabs = false
                        } label: {
                            Label("New tab", systemImage: "plus")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 13).padding(.vertical, 9)
                                .background(GlassAppearance.accent(for: themePreset), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 11), GridItem(.flexible(), spacing: 11)], spacing: 11) {
                        ForEach(browser.visibleTabs) { tab in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: tab.isPrivate ? "eye.slash.fill" : "globe")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(GlassAppearance.accent(for: themePreset))
                                        .frame(width: 34, height: 34)
                                        .background(GlassAppearance.accent(for: themePreset).opacity(0.14), in: RoundedRectangle(cornerRadius: 11))
                                    Spacer()
                                    if browser.activeTabID == tab.id {
                                        Text("ACTIVE")
                                            .font(.system(size: 8, weight: .bold)).tracking(1)
                                            .foregroundStyle(GlassAppearance.accent(for: themePreset))
                                    }
                                    Button { browser.close(tab) } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(GlassPalette.secondary)
                                            .frame(width: 25, height: 25)
                                            .background(Color.white.opacity(0.07), in: Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Close tab")
                                }
                                Spacer(minLength: 3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tab.title.isEmpty ? "New tab" : tab.title)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.white).lineLimit(2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(tab.address.isEmpty ? "GLASS start page" : tab.address)
                                        .font(.system(size: 9))
                                        .foregroundStyle(GlassPalette.secondary).lineLimit(1)
                                }
                            }
                            .padding(13)
                            .frame(minHeight: 132, alignment: .topLeading)
                            .background(.ultraThinMaterial.opacity(themeBlur), in: RoundedRectangle(cornerRadius: themeCornerRadius, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: themeCornerRadius).fill(Color.white.opacity(themeCardOpacity)))
                            .overlay(RoundedRectangle(cornerRadius: themeCornerRadius).stroke(browser.activeTabID == tab.id ? GlassAppearance.accent(for: themePreset).opacity(0.55) : GlassPalette.line, lineWidth: browser.activeTabID == tab.id ? 1.4 : 1))
                            .contentShape(RoundedRectangle(cornerRadius: themeCornerRadius))
                            .onTapGesture {
                                browser.select(tab)
                                showTabs = false
                            }
                        }
                    }
                    if browser.visibleTabs.isEmpty {
                        ContentUnavailableView("No open tabs", systemImage: "square.on.square", description: Text("Create a tab to start browsing."))
                            .frame(maxWidth: .infinity).padding(.top, 36)
                    }
                }
                .padding(16)
            }
            .background(GlassPalette.background.ignoresSafeArea())
            .navigationTitle("Tabs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { showTabs = false }
                }
            }
        }
        .tint(GlassAppearance.accent(for: themePreset))
        .preferredColorScheme(.dark)
    }

    private var spacesSheet: some View {
        NavigationStack {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    TextField("New space name", text: $newSpaceName)
                        .textFieldStyle(.roundedBorder).submitLabel(.done).onSubmit(addSpace)
                    Button(action: addSpace) {
                        Image(systemName: "plus").font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white).frame(width: 38, height: 38)
                            .background(GlassAppearance.accent(for: themePreset), in: Circle())
                    }
                    .disabled(newSpaceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                List {
                    ForEach(browser.spaces) { space in
                        HStack(spacing: 12) {
                            Image(systemName: space.symbol).foregroundStyle(spaceColor(space.tint)).frame(width: 26)
                            Text(space.name).foregroundStyle(.white)
                            Spacer()
                            if browser.activeSpaceID == space.id {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(GlassAppearance.accent(for: themePreset))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            browser.selectSpace(space)
                            showSpaces = false
                        }
                        .listRowBackground(Color.white.opacity(themePanelOpacity))
                        .swipeActions {
                            if space.id != "personal" {
                                Button(role: .destructive) { browser.removeSpace(space) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .padding(.top, 14).background(GlassPalette.background.ignoresSafeArea())
            .navigationTitle("Spaces").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { showSpaces = false } }
            }
        }
        .tint(GlassAppearance.accent(for: themePreset))
    }

    private func addSpace() {
        browser.createSpace(name: newSpaceName)
        newSpaceName = ""
        showSpaces = false
    }

    private func libraryRow(title: String, subtitle: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).foregroundStyle(GlassAppearance.accent(for: themePreset)).frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 14, weight: .medium)).foregroundStyle(.white).lineLimit(1)
                    Text(subtitle).font(.system(size: 11)).foregroundStyle(GlassPalette.secondary).lineLimit(1)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(Color.white.opacity(themePanelOpacity))
    }

    private func openLibraryURL(_ value: String) {
        guard let url = URL(string: value) else { return }
        if browser.activeTab == nil { browser.addTab() }
        browser.activeTab?.load(url)
        showLibrary = false
    }

    private func navigationButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 16, weight: .medium))
                .foregroundStyle(enabled ? .white : GlassPalette.secondary.opacity(0.3)).frame(width: 34, height: 38)
        }
        .disabled(!enabled)
    }

    private func spaceColor(_ tint: String) -> Color {
        switch tint {
        case "blue": return Color(red: 0.30, green: 0.62, blue: 1.0)
        case "green": return Color(red: 0.28, green: 0.82, blue: 0.58)
        case "orange": return Color(red: 1.0, green: 0.62, blue: 0.30)
        default: return GlassAppearance.accent(for: themePreset)
        }
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
            destination = browser.searchURL(for: input)
        }
        guard let destination else { return }
        tab.load(destination)
        hideKeyboard()
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
