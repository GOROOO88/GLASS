import SwiftUI
import UIKit

private struct AutomaticTabGroup: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let subtitle: String
    let tabs: [BrowserTab]
}

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
    @State private var collapsedTabGroups: Set<String> = []
    @State private var tabsSearchText = ""
    @State private var confirmCloseSpaceTabs = false
    @State private var screenFadeOpacity = 0.0

    private var isPrivateMode: Bool { browser.activeTab?.isPrivate == true }
    private var activeAccent: Color {
        isPrivateMode ? GlassAppearance.privateAccent : GlassAppearance.accent(for: themePreset)
    }

    var body: some View {
        ZStack {
            Group {
                if isPrivateMode {
                    ZStack {
                        GlassAppearance.privateBackground
                        RadialGradient(
                            colors: [GlassAppearance.privateAccent.opacity(0.24), .clear],
                            center: .top,
                            startRadius: 8,
                            endRadius: 460
                        )
                        RadialGradient(
                            colors: [Color(red: 0.48, green: 0.13, blue: 0.12).opacity(0.12), .clear],
                            center: .bottomTrailing,
                            startRadius: 5,
                            endRadius: 300
                        )
                    }
                } else {
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
                            colors: [activeAccent.opacity(0.25), .clear],
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
                                .id(tab.id)
                                .transition(.opacity)
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

            Color.black
                .ignoresSafeArea()
                .opacity(screenFadeOpacity)
                .allowsHitTesting(screenFadeOpacity > 0.02)
                .accessibilityHidden(true)
        }
        .animation(.easeInOut(duration: 0.08 + themeMotion * 0.42), value: themePreset)
        .animation(.easeInOut(duration: 0.22 + themeMotion * 0.20), value: browser.activeTabID)
        .onChange(of: isPrivateMode) { _, _ in
            playScreenFade()
        }
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
            Button("Отмена", role: .cancel) {}
            Button("Очистить данные", role: .destructive) {
                browser.clearWebsiteData {
                    privacyActionMessage = "Cookies, cache and website storage were cleared."
                }
            }
        } message: {
            Text("Вы выйдете из аккаунтов на многих сайтах. Закладки и загруженные файлы останутся.")
        }
        .alert("Privacy", isPresented: Binding(
            get: { !privacyActionMessage.isEmpty },
            set: { if !$0 { privacyActionMessage = "" } }
        )) {
            Button("Понятно") { privacyActionMessage = "" }
        } message: {
            Text(privacyActionMessage)
        }
    }

    private func playScreenFade() {
        guard themeMotion > 0.02 else { return }
        withAnimation(.easeIn(duration: 0.13)) {
            screenFadeOpacity = 0.88
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.easeOut(duration: 0.34 + themeMotion * 0.18)) {
                screenFadeOpacity = 0
            }
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "circle.hexagongrid.fill").foregroundStyle(activeAccent)
                Text("GLASS").font(.system(size: 17, weight: .bold, design: .rounded)).tracking(2.4)
            }
            if isPrivateMode {
                HStack(spacing: 5) {
                    Image(systemName: "eye.slash.fill").font(.system(size: 9, weight: .bold))
                    Text("ПРИВАТНО").font(.system(size: 9, weight: .bold)).tracking(1.1)
                }
                .foregroundStyle(GlassAppearance.privateAccent)
                .padding(.horizontal, 9).padding(.vertical, 7)
                .background(GlassAppearance.privateAccent.opacity(0.13), in: Capsule())
                .overlay(Capsule().stroke(GlassAppearance.privateAccent.opacity(0.38), lineWidth: 0.9))
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
            .accessibilityLabel("Библиотека")
            Button {
                librarySection = 2
                showLibrary = true
            } label: {
                Image(systemName: "arrow.down.circle").font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white).frame(width: 42, height: 42)
                    .background(Color.white.opacity(themePanelOpacity), in: Circle()).overlay(Circle().stroke(GlassPalette.line))
            }
            .accessibilityLabel("Загрузки")
            Button {
                showSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3").font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white).frame(width: 42, height: 42)
                    .background(Color.white.opacity(themePanelOpacity), in: Circle()).overlay(Circle().stroke(GlassPalette.line))
            }
            .accessibilityLabel("Настройки браузера")
            Button {
                showPrivacy = true
            } label: {
                Image(systemName: "hand.raised").font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white).frame(width: 42, height: 42)
                    .background(Color.white.opacity(themePanelOpacity), in: Circle()).overlay(Circle().stroke(GlassPalette.line))
            }
            .accessibilityLabel("Настройки приватности")
        }
    }

    private var addressBar: some View {
        HStack(spacing: 10) {
            if browser.activeTab?.isPrivate == true {
                Image(systemName: "eye.slash.fill").foregroundStyle(GlassAppearance.privateAccent)
            } else {
                Image(systemName: "magnifyingglass").foregroundStyle(GlassPalette.secondary)
            }
            TextField(browser.activeTab?.isPrivate == true ? "Private browsing" : "Search or enter address", text: $addressText)
                .font(.system(size: 15)).textInputAutocapitalization(.never)
                .autocorrectionDisabled().keyboardType(.URL).submitLabel(.go).onSubmit(openAddress)
            if let tab = browser.activeTab, tab.isLoading {
                ProgressView().tint(activeAccent)
            } else {
                Button(action: openAddress) {
                    Image(systemName: "arrow.up.right").font(.system(size: 14, weight: .bold)).foregroundStyle(activeAccent)
                }
                .accessibilityLabel("Открыть адрес")
            }
            if let tab = browser.activeTab, !tab.isPrivate, !tab.address.isEmpty {
                Button {
                    browser.toggleBookmark(url: tab.address, title: tab.title)
                } label: {
                    Image(systemName: browser.isBookmarked(tab.address) ? "star.fill" : "star")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(activeAccent)
                }
                .accessibilityLabel(browser.isBookmarked(tab.address) ? "Remove bookmark" : "Add bookmark")
            }
        }
        .padding(.horizontal, 15).frame(height: 54)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: themeCornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: themeCornerRadius).fill(Color.white.opacity(themeAddressOpacity)))
        .overlay(RoundedRectangle(cornerRadius: themeCornerRadius).stroke(Color.white.opacity(0.15)))
        .shadow(color: activeAccent.opacity(themeGlow * 0.12), radius: 16, y: 5)
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
                .accessibilityLabel("Управление пространствами")
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
                        .accessibilityLabel("Закрыть вкладку")
                    }
                    .padding(.horizontal, 12).frame(height: 36)
                    .background(tab.isPrivate ? GlassAppearance.privateAccent.opacity(0.20) : (browser.activeTabID == tab.id ? activeAccent.opacity(0.24) : Color.white.opacity(themePanelOpacity)), in: Capsule())
                    .overlay(Capsule().stroke(tab.isPrivate ? GlassAppearance.privateAccent.opacity(browser.activeTabID == tab.id ? 0.78 : 0.38) : (browser.activeTabID == tab.id ? activeAccent.opacity(0.45) : GlassPalette.line)))
                    .contextMenu {
                        ForEach(browser.spaces.filter { $0.id != tab.spaceID }) { destination in
                            Button {
                                browser.move(tab, to: destination)
                            } label: {
                                Label("Переместить в \(destination.name)", systemImage: destination.symbol)
                            }
                        }
                    }
                }
                Button { browser.addTab() } label: {
                    Image(systemName: "plus").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                        .frame(width: 36, height: 36).background(Color.white.opacity(themePanelOpacity), in: Circle()).overlay(Circle().stroke(GlassPalette.line))
                }
                .accessibilityLabel("Новая вкладка")
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
                        .foregroundStyle(GlassAppearance.privateAccent)
                        .shadow(color: GlassAppearance.privateAccent.opacity(themeGlow), radius: 24)
                    Text("ПРИВАТНЫЙ РЕЖИМ")
                        .font(.system(size: 23, weight: .bold, design: .rounded)).tracking(3)
                        .foregroundStyle(GlassAppearance.privateAccent)
                    Text("Эта сессия остаётся на устройстве и не сохраняется в истории.")
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
                                    .foregroundStyle(activeAccent)
                                Text("GLASS")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .tracking(3).foregroundStyle(.white.opacity(0.8))
                                Spacer()
                                Text("ВАШЕ ПРОСТРАНСТВО")
                                    .font(.system(size: 9, weight: .bold)).tracking(1.6)
                                    .foregroundStyle(GlassPalette.secondary)
                            }
                            Text("Ваше личное\nпространство в сети.")
                                .font(.system(size: 34, weight: .semibold, design: .rounded))
                                .tracking(-0.8).foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Всё нужное всегда под рукой.")
                                .font(.system(size: 13)).foregroundStyle(GlassPalette.secondary)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            LinearGradient(
                                colors: [
                                    activeAccent.opacity(0.23),
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
                            sectionHeading("БЫСТРЫЙ ДОСТУП", subtitle: "Любимые сайты всегда под рукой")
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                quickLink("YouTube", subtitle: "Видео", symbol: "play.rectangle.fill", url: "https://www.youtube.com")
                                quickLink("Spotify", subtitle: "Музыка", symbol: "waveform", url: "https://open.spotify.com")
                                quickLink("Reddit", subtitle: "Сообщество", symbol: "bubble.left.and.bubble.right.fill", url: "https://www.reddit.com")
                                quickLink("Wikipedia", subtitle: "Знания", symbol: "book.closed.fill", url: "https://www.wikipedia.org")
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeading("ПРОСТРАНСТВА", subtitle: "Разделяйте разные сферы жизни")
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
                                                    .foregroundStyle(browser.activeSpaceID == space.id ? activeAccent : GlassPalette.secondary)
                                            }
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(space.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                                                Text(browser.activeSpaceID == space.id ? "Сейчас открыто" : "Открыть пространство")
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
                                sectionHeading("НЕДАВНО ПОСЕЩЁННЫЕ", subtitle: "Продолжить с того места, где остановились")
                                Spacer()
                                Button("История") { librarySection = 0; showLibrary = true }
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(activeAccent)
                            }
                            if browser.history.isEmpty {
                                HStack(spacing: 10) {
                                    Image(systemName: "clock").foregroundStyle(GlassPalette.secondary)
                                    Text("Здесь появятся недавно посещённые страницы.")
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
                                                    .font(.system(size: 14)).foregroundStyle(activeAccent)
                                                    .frame(width: 30, height: 30)
                                                    .background(activeAccent.opacity(0.13), in: Circle())
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

                        if !browser.recentlyClosed.isEmpty {
                            VStack(alignment: .leading, spacing: 11) {
                                HStack {
                                    sectionHeading("НЕДАВНО ЗАКРЫТЫЕ", subtitle: "Вернуть закрытую страницу")
                                    Spacer()
                                    Button("Очистить") { browser.clearRecentlyClosed() }
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(GlassPalette.secondary)
                                }
                                VStack(spacing: 0) {
                                    ForEach(Array(browser.recentlyClosed.prefix(3))) { item in
                                        Button { browser.reopen(item) } label: {
                                            HStack(spacing: 11) {
                                                Image(systemName: "arrow.uturn.backward")
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundStyle(activeAccent)
                                                    .frame(width: 30, height: 30)
                                                    .background(activeAccent.opacity(0.13), in: Circle())
                                                VStack(alignment: .leading, spacing: 3) {
                                                    Text(item.title).font(.system(size: 12, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                                                    Text(URL(string: item.url)?.host ?? item.url).font(.system(size: 10)).foregroundStyle(GlassPalette.secondary).lineLimit(1)
                                                }
                                                Spacer()
                                                Image(systemName: "arrow.clockwise").font(.system(size: 10, weight: .semibold)).foregroundStyle(GlassPalette.secondary)
                                            }
                                            .padding(.vertical, 10).padding(.horizontal, 12)
                                        }
                                        .buttonStyle(.plain)
                                        if item.id != browser.recentlyClosed.prefix(3).last?.id {
                                            Divider().overlay(Color.white.opacity(0.07)).padding(.leading, 52)
                                        }
                                    }
                                }
                                .background(.ultraThinMaterial.opacity(themeBlur), in: RoundedRectangle(cornerRadius: themeCornerRadius))
                                .overlay(RoundedRectangle(cornerRadius: themeCornerRadius).fill(Color.white.opacity(themeCardOpacity)))
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
                    .foregroundStyle(activeAccent)
                    .frame(width: 34, height: 34)
                    .background(activeAccent.opacity(0.14), in: RoundedRectangle(cornerRadius: 11))
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
            dockButton("chevron.left", title: "Назад", enabled: browser.activeTab?.canGoBack == true) {
                browser.activeTab?.goBack()
            }
            Spacer(minLength: 2)
            dockButton("chevron.right", title: "Вперёд", enabled: browser.activeTab?.canGoForward == true) {
                browser.activeTab?.goForward()
            }
            Spacer(minLength: 2)
            dockButton("books.vertical", title: "Библиотека", enabled: true) {
                librarySection = 1
                showLibrary = true
            }
            Spacer(minLength: 2)
            dockButton("clock.arrow.circlepath", title: "История", enabled: true) {
                librarySection = 0
                showLibrary = true
            }
            Spacer(minLength: 2)
            dockButton("square.on.square", title: "Вкладки", enabled: true) {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) { showTabs = true }
            }
            Spacer(minLength: 2)
            Button {
                browser.addTab()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(activeAccent, in: Circle())
                    .shadow(color: activeAccent.opacity(themeGlow), radius: 12, y: 3)
            }
            .accessibilityLabel("Новая вкладка")
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
                    Text("История").tag(0)
                    Text("Закладки").tag(1)
                    Text("Загрузки").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(5)
                .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .padding(.horizontal, 16)
                if librarySection == 0 {
                    if browser.history.isEmpty {
                        ContentUnavailableView("История пока пуста", systemImage: "clock", description: Text("Посещённые страницы появятся здесь."))
                    } else {
                        List {
                            ForEach(browser.history, id: \.self) { url in
                                libraryRow(title: URL(string: url)?.host ?? url, subtitle: url, symbol: "clock") { openLibraryURL(url) }
                            }
                        }.listStyle(.plain).scrollContentBackground(.hidden).listRowSeparatorTint(Color.white.opacity(0.07))
                    }
                } else if librarySection == 1 {
                    if browser.bookmarks.isEmpty {
                        ContentUnavailableView("Закладок пока нет", systemImage: "star", description: Text("Нажмите на звёздочку в адресной строке, чтобы сохранить страницу."))
                    } else {
                        List {
                            ForEach(browser.bookmarks) { bookmark in
                                libraryRow(title: bookmark.title, subtitle: bookmark.url, symbol: "star") { openLibraryURL(bookmark.url) }
                                    .swipeActions {
                                        Button(role: .destructive) { browser.removeBookmark(bookmark) } label: {
                                            Label("Удалить", systemImage: "trash")
                                        }
                                    }
                            }
                        }.listStyle(.plain).scrollContentBackground(.hidden)
                    }
                } else {
                    if browser.downloads.isEmpty && browser.activeDownloads.isEmpty {
                        ContentUnavailableView("Загрузок пока нет", systemImage: "arrow.down.circle", description: Text("Загруженные с сайтов файлы появятся здесь."))
                    } else {
                        List {
                            ForEach(browser.activeDownloads) { download in
                                HStack(spacing: 10) {
                                    Image(systemName: download.failure == nil ? "arrow.down.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundStyle(download.failure == nil ? activeAccent : .orange)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(download.filename).font(.system(size: 13, weight: .medium)).foregroundStyle(.white).lineLimit(1)
                                        if let failure = download.failure {
                                            Text(failure).font(.system(size: 10)).foregroundStyle(.orange).lineLimit(2)
                                        } else {
                                            ProgressView(value: download.progress).tint(activeAccent)
                                            Text("\(Int(download.progress * 100))%")
                                                .font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(GlassPalette.secondary)
                                        }
                                    }
                                    Spacer()
                                    if download.failure != nil {
                                        Button { browser.retryDownload(download) } label: {
                                            Image(systemName: "arrow.clockwise").foregroundStyle(activeAccent)
                                        }
                                        .accessibilityLabel("Повторить загрузку")
                                    } else {
                                        Button(role: .destructive) { browser.cancelDownload(download) } label: {
                                            Image(systemName: "xmark.circle.fill").foregroundStyle(.orange)
                                        }
                                        .accessibilityLabel("Отменить загрузку")
                                    }
                                }
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.ultraThinMaterial.opacity(themeBlur))
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                                )
                            }
                            ForEach(browser.downloads) { download in
                                HStack(spacing: 10) {
                                    Image(systemName: "doc.fill").foregroundStyle(activeAccent).frame(width: 28)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(download.filename).font(.system(size: 13, weight: .medium)).foregroundStyle(.white).lineLimit(1)
                                        Text(download.completedAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.system(size: 10)).foregroundStyle(GlassPalette.secondary)
                                    }
                                    Spacer()
                                    ShareLink(item: download.fileURL) {
                                        Image(systemName: "square.and.arrow.up").foregroundStyle(activeAccent)
                                    }
                                }
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.ultraThinMaterial.opacity(themeBlur))
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                                )
                                .swipeActions {
                                    Button(role: .destructive) { browser.removeDownload(download) } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                            }
                        }.listStyle(.plain).scrollContentBackground(.hidden)
                    }
                }
            }
            .padding(.top, 12).background(GlassPalette.background.ignoresSafeArea())
            .navigationTitle("Библиотека").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if librarySection == 0 && !browser.history.isEmpty {
                        Button("Очистить") { browser.clearHistory() }
                    } else if librarySection == 2 && !browser.downloads.isEmpty {
                        Button("Очистить") { browser.clearDownloads() }
                    }
                }
                ToolbarItem(placement: .topBarLeading) { Button("Готово") { showLibrary = false } }
            }
        }
        .tint(activeAccent)
        .preferredColorScheme(.dark)
    }

    private var privacySheet: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "eye.slash.circle.fill").font(.system(size: 24)).foregroundStyle(activeAccent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Приватные вкладки").foregroundStyle(.white)
                            Text("Используют отдельное временное хранилище. После закрытия GLASS приватные вкладки не восстанавливаются.")
                                .font(.system(size: 12)).foregroundStyle(GlassPalette.secondary)
                        }
                    }
                    .listRowBackground(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.ultraThinMaterial.opacity(themeBlur))
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                                )
                    HStack(spacing: 12) {
                        Image(systemName: "clock.badge.xmark").font(.system(size: 22)).foregroundStyle(activeAccent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("История браузера").foregroundStyle(.white)
                            Text("Обычные вкладки сохраняют адреса посещённых страниц на устройстве. Приватные вкладки этого не делают.")
                                .font(.system(size: 12)).foregroundStyle(GlassPalette.secondary)
                        }
                    }
                    .listRowBackground(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.ultraThinMaterial.opacity(themeBlur))
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                                )
                } header: {
                    Text("Приватность на устройстве")
                }
                Section {
                    Button(role: .destructive) {
                        confirmClearWebsiteData = true
                    } label: {
                        Label("Очистить cookie, кэш и данные сайтов", systemImage: "trash")
                    }
                    .listRowBackground(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.ultraThinMaterial.opacity(themeBlur))
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                                )
                    Button(role: .destructive) {
                        browser.clearHistory()
                        privacyActionMessage = "Browsing history was cleared."
                    } label: {
                        Label("Очистить историю браузера", systemImage: "clock")
                    }
                    .listRowBackground(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.ultraThinMaterial.opacity(themeBlur))
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                                )
                } header: {
                    Text("Очистка данных")
                } footer: {
                    Text("После очистки данных сайтов может потребоваться повторный вход в аккаунты. Закладки и загруженные файлы не удаляются.")
                }
            }
            .scrollContentBackground(.hidden)
            .listRowSeparatorTint(Color.white.opacity(0.07))
            .background(GlassPalette.background)
            .navigationTitle("Приватность").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Готово") { showPrivacy = false } }
            }
        }
        .tint(activeAccent)
        .preferredColorScheme(.dark)
    }

    private var automaticTabGroups: [AutomaticTabGroup] {
        let grouped = Dictionary(grouping: browser.visibleTabs) { tab in
            if tab.isPrivate { return "private" }
            return tab.groupKind
        }
        let order = ["new", "search", "searchResult", "opened", "direct", "private"]
        let metadata: [String: (String, String, String)] = [
            "new": ("Новые вкладки", "plus.square", "Пустые вкладки для новых страниц"),
            "search": ("Поисковые вкладки", "magnifyingglass", "Выполненные поисковые запросы"),
            "searchResult": ("Открыты из поиска", "arrow.up.right", "Страницы из результатов поиска"),
            "opened": ("Открыты по ссылке", "link", "Страницы, открытые по ссылкам"),
            "direct": ("Открыты напрямую", "globe", "Адреса, введённые вручную"),
            "private": ("Приватные вкладки", "eye.slash.fill", "Временные приватные сессии")
        ]
        return order.compactMap { key in
            guard let tabs = grouped[key], !tabs.isEmpty, let info = metadata[key] else { return nil }
            let filtered = tabs.filter { tab in
                let query = tabsSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !query.isEmpty else { return true }
                return tab.title.localizedCaseInsensitiveContains(query)
                    || tab.address.localizedCaseInsensitiveContains(query)
                    || tab.groupDetail.localizedCaseInsensitiveContains(query)
            }
            guard !filtered.isEmpty else { return nil }
            return AutomaticTabGroup(id: key, title: info.0, symbol: info.1, subtitle: info.2, tabs: filtered)
        }
    }

    private var tabsSheet: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 17) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ВАШИ ВКЛАДКИ")
                                .font(.system(size: 10, weight: .bold)).tracking(1.6)
                                .foregroundStyle(GlassPalette.secondary)
                            Text("Открыто: \(browser.visibleTabs.count)")
                                .font(.system(size: 23, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Автоматическая группировка по способу открытия")
                                .font(.system(size: 11)).foregroundStyle(GlassPalette.secondary)
                        }
                        Spacer()
                        Button {
                            confirmCloseSpaceTabs = true
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.78))
                                .frame(width: 36, height: 36)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(Circle().stroke(.white.opacity(0.12)))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Закрыть все вкладки пространства")
                        Button {
                            browser.addTab()
                            showTabs = false
                        } label: {
                            Label("Новая вкладка", systemImage: "plus")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 13).padding(.vertical, 10)
                                .background(activeAccent.opacity(0.88), in: Capsule())
                                .overlay(Capsule().stroke(.white.opacity(0.18)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(15)
                    .background(.ultraThinMaterial.opacity(themeBlur), in: RoundedRectangle(cornerRadius: themeCornerRadius + 2, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: themeCornerRadius + 2).fill(Color.white.opacity(themeCardOpacity)))
                    .overlay(RoundedRectangle(cornerRadius: themeCornerRadius + 2).stroke(.white.opacity(0.12)))

                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(GlassPalette.secondary)
                        TextField("Поиск по открытым вкладкам", text: $tabsSearchText)
                            .font(.system(size: 13))
                            .foregroundStyle(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        if !tabsSearchText.isEmpty {
                            Button { tabsSearchText = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(GlassPalette.secondary)
                            }.buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(.ultraThinMaterial.opacity(themeBlur), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(themeCardOpacity)))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.10)))

                    ForEach(automaticTabGroups) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            Button {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                                    if collapsedTabGroups.contains(group.id) {
                                        collapsedTabGroups.remove(group.id)
                                    } else {
                                        collapsedTabGroups.insert(group.id)
                                    }
                                }
                            } label: {
                                HStack(spacing: 9) {
                                    Image(systemName: group.symbol)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(activeAccent)
                                        .frame(width: 30, height: 30)
                                        .background(activeAccent.opacity(0.13), in: RoundedRectangle(cornerRadius: 10))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(group.title)
                                            .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                                        Text(group.subtitle)
                                            .font(.system(size: 9)).foregroundStyle(GlassPalette.secondary)
                                    }
                                    Text("\(group.tabs.count)")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundStyle(GlassPalette.secondary)
                                        .padding(.horizontal, 7).padding(.vertical, 4)
                                        .background(.ultraThinMaterial, in: Capsule())
                                    Spacer()
                                    Image(systemName: collapsedTabGroups.contains(group.id) ? "chevron.down" : "chevron.up")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(GlassPalette.secondary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if !collapsedTabGroups.contains(group.id) {
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                    ForEach(group.tabs) { tab in
                                        tabCard(tab)
                                            .draggable(tab.id.uuidString)
                                            .dropDestination(for: String.self) { items, _ in
                                                guard let rawID = items.first, let sourceID = UUID(uuidString: rawID),
                                                      let source = browser.visibleTabs.first(where: { $0.id == sourceID }) else { return false }
                                                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                                    browser.moveTab(source, before: tab)
                                                }
                                                return true
                                            }
                                    }
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(13)
                        .background(.ultraThinMaterial.opacity(themeBlur * 0.8), in: RoundedRectangle(cornerRadius: themeCornerRadius + 2, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: themeCornerRadius + 2).fill(Color.white.opacity(themePanelOpacity * 0.72)))
                        .overlay(RoundedRectangle(cornerRadius: themeCornerRadius + 2).stroke(.white.opacity(0.09)))
                    }

                    if !tabsSearchText.isEmpty && automaticTabGroups.isEmpty {
                        ContentUnavailableView("Вкладки не найдены", systemImage: "magnifyingglass", description: Text("Измените название, адрес или поисковый запрос."))
                            .frame(maxWidth: .infinity).padding(.top, 36)
                    }

                    if browser.visibleTabs.isEmpty {
                        ContentUnavailableView("Нет открытых вкладок", systemImage: "square.on.square", description: Text("Создайте вкладку, чтобы начать просмотр."))
                            .frame(maxWidth: .infinity).padding(.top, 36)
                    }
                }
                .padding(16)
            }
            .background(GlassPalette.background.ignoresSafeArea())
            .confirmationDialog("Закрыть все вкладки этого пространства?", isPresented: $confirmCloseSpaceTabs, titleVisibility: .visible) {
                Button("Закрыть все вкладки", role: .destructive) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        browser.closeAllTabsInActiveSpace()
                    }
                }
                Button("Отмена", role: .cancel) {}
            }
            .navigationTitle("Вкладки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Готово") { showTabs = false }
                }
            }
        }
        .tint(activeAccent)
        .preferredColorScheme(.dark)
    }

    private func tabContext(_ tab: BrowserTab) -> String {
        switch tab.groupKind {
        case "search": return "Поиск: \(tab.groupDetail)"
        case "searchResult": return "Из поиска: \(tab.groupDetail)"
        case "opened": return "Открыта с сайта: \(tab.groupDetail)"
        default: return tab.groupDetail
        }
    }

    private func tabCard(_ tab: BrowserTab) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Image(systemName: tab.isPrivate ? "eye.slash.fill" : "globe")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(activeAccent)
                    .frame(width: 32, height: 32)
                    .background(activeAccent.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
                Spacer()
                if browser.activeTabID == tab.id {
                    Text("АКТИВНАЯ")
                        .font(.system(size: 8, weight: .bold)).tracking(1)
                        .foregroundStyle(activeAccent)
                }
                Button { browser.close(tab) } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(GlassPalette.secondary)
                        .frame(width: 24, height: 24)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Закрыть вкладку")
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(tab.title.isEmpty ? "Новая вкладка" : tab.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white).lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !tab.groupDetail.isEmpty {
                    Text(tabContext(tab))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(activeAccent.opacity(0.92))
                        .lineLimit(1)
                }
                Text(tab.address.isEmpty ? "Стартовая страница GLASS" : tab.address)
                    .font(.system(size: 9))
                    .foregroundStyle(GlassPalette.secondary).lineLimit(1)
            }
        }
        .padding(12)
        .frame(minHeight: 116, alignment: .topLeading)
        .background(.ultraThinMaterial.opacity(themeBlur), in: RoundedRectangle(cornerRadius: themeCornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: themeCornerRadius).fill(Color.white.opacity(themeCardOpacity)))
        .overlay(RoundedRectangle(cornerRadius: themeCornerRadius).stroke(browser.activeTabID == tab.id ? activeAccent.opacity(0.62) : .white.opacity(0.11), lineWidth: browser.activeTabID == tab.id ? 1.4 : 1))
        .contentShape(RoundedRectangle(cornerRadius: themeCornerRadius))
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: browser.activeTabID)
        .onTapGesture {
            browser.select(tab)
            showTabs = false
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 28)
                .onEnded { value in
                    let horizontal = abs(value.translation.width)
                    let vertical = abs(value.translation.height)
                    guard horizontal > 88, horizontal > vertical * 1.35 else { return }
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                        browser.close(tab)
                    }
                }
        )
        .contextMenu {
            Button {
                browser.duplicate(tab)
                showTabs = false
            } label: {
                Label("Дублировать вкладку", systemImage: "plus.square.on.square")
            }

            Menu {
                ForEach(browser.spaces.filter { $0.id != tab.spaceID }) { space in
                    Button {
                        browser.move(tab, to: space)
                    } label: {
                        Label(space.name, systemImage: space.symbol)
                    }
                }
            } label: {
                Label("Переместить в пространство", systemImage: "square.grid.2x2")
            }

            Button(role: .destructive) {
                browser.close(tab)
            } label: {
                Label("Закрыть вкладку", systemImage: "xmark")
            }
        }
    }

    private var spacesSheet: some View {
        NavigationStack {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    TextField("Название пространства", text: $newSpaceName)
                        .textFieldStyle(.roundedBorder).submitLabel(.done).onSubmit(addSpace)
                    Button(action: addSpace) {
                        Image(systemName: "plus").font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white).frame(width: 38, height: 38)
                            .background(activeAccent, in: Circle())
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
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(activeAccent)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            browser.selectSpace(space)
                            showSpaces = false
                        }
                        .listRowBackground(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.ultraThinMaterial.opacity(themeBlur))
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                                )
                        .swipeActions {
                            if space.id != "personal" {
                                Button(role: .destructive) { browser.removeSpace(space) } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .padding(.top, 14).background(GlassPalette.background.ignoresSafeArea())
            .navigationTitle("Пространства").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Готово") { showSpaces = false } }
            }
        }
        .tint(activeAccent)
    }

    private func addSpace() {
        browser.createSpace(name: newSpaceName)
        newSpaceName = ""
        showSpaces = false
    }

    private func libraryRow(title: String, subtitle: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).foregroundStyle(activeAccent).frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 14, weight: .medium)).foregroundStyle(.white).lineLimit(1)
                    Text(subtitle).font(.system(size: 11)).foregroundStyle(GlassPalette.secondary).lineLimit(1)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.ultraThinMaterial.opacity(themeBlur))
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                                )
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
        default: return activeAccent
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
