import SwiftUI
import UIKit

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
    @State private var showLibrary = false
    @State private var librarySection = 0
    @State private var showSpaces = false
    @State private var newSpaceName = ""

    var body: some View {
        ZStack {
            GlassPalette.background.ignoresSafeArea()
            RadialGradient(colors: [GlassPalette.accent.opacity(0.18), .clear], center: .top, startRadius: 8, endRadius: 420)
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
            .padding(.bottom, 8)
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
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "circle.hexagongrid.fill").foregroundStyle(GlassPalette.accent)
                Text("GLASS").font(.system(size: 17, weight: .bold, design: .rounded)).tracking(2.4)
            }
            Spacer()
            Button {
                librarySection = 1
                showLibrary = true
            } label: {
                Image(systemName: "books.vertical").font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white).frame(width: 42, height: 42)
                    .background(GlassPalette.panel, in: Circle()).overlay(Circle().stroke(GlassPalette.line))
            }
            .accessibilityLabel("Library")
            Button {} label: {
                Image(systemName: "sparkle").font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white).frame(width: 42, height: 42)
                    .background(GlassPalette.panel, in: Circle()).overlay(Circle().stroke(GlassPalette.line))
            }
            .accessibilityLabel("AI assistant")
        }
    }

    private var addressBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(GlassPalette.secondary)
            TextField("Search or enter address", text: $addressText)
                .font(.system(size: 15)).textInputAutocapitalization(.never)
                .autocorrectionDisabled().keyboardType(.URL).submitLabel(.go).onSubmit(openAddress)
            if let tab = browser.activeTab, tab.isLoading {
                ProgressView().tint(GlassPalette.accent)
            } else {
                Button(action: openAddress) {
                    Image(systemName: "arrow.up.right").font(.system(size: 14, weight: .bold)).foregroundStyle(GlassPalette.accent)
                }
                .accessibilityLabel("Open address")
            }
            if let tab = browser.activeTab, !tab.address.isEmpty {
                Button {
                    browser.toggleBookmark(url: tab.address, title: tab.title)
                } label: {
                    Image(systemName: browser.isBookmarked(tab.address) ? "star.fill" : "star")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(GlassPalette.accent)
                }
                .accessibilityLabel(browser.isBookmarked(tab.address) ? "Remove bookmark" : "Add bookmark")
            }
        }
        .padding(.horizontal, 15).frame(height: 52)
        .background(GlassPalette.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(GlassPalette.line))
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
                        .background(browser.activeSpaceID == space.id ? spaceColor(space.tint).opacity(0.30) : GlassPalette.panel, in: Capsule())
                        .overlay(Capsule().stroke(browser.activeSpaceID == space.id ? spaceColor(space.tint).opacity(0.75) : GlassPalette.line))
                    }
                }
                Button {
                    showSpaces = true
                } label: {
                    Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white).frame(width: 34, height: 34)
                        .background(GlassPalette.panel, in: Circle()).overlay(Circle().stroke(GlassPalette.line))
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
                            Text(tab.title).font(.system(size: 12, weight: .medium)).lineLimit(1)
                                .foregroundStyle(browser.activeTabID == tab.id ? .white : GlassPalette.secondary)
                        }
                        Button { browser.close(tab) } label: {
                            Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).foregroundStyle(GlassPalette.secondary)
                        }
                        .accessibilityLabel("Close tab")
                    }
                    .padding(.horizontal, 12).frame(height: 36)
                    .background(browser.activeTabID == tab.id ? GlassPalette.accent.opacity(0.24) : GlassPalette.panel, in: Capsule())
                    .overlay(Capsule().stroke(browser.activeTabID == tab.id ? GlassPalette.accent.opacity(0.45) : GlassPalette.line))
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
                        .frame(width: 36, height: 36).background(GlassPalette.panel, in: Circle()).overlay(Circle().stroke(GlassPalette.line))
                }
                .accessibilityLabel("New tab")
            }
        }
    }

    private var startPage: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "circle.hexagongrid.fill").font(.system(size: 42, weight: .light))
                .foregroundStyle(GlassPalette.accent).shadow(color: GlassPalette.accent.opacity(0.55), radius: 24)
            Text("GLASS").font(.system(size: 31, weight: .bold, design: .rounded)).tracking(7).foregroundStyle(.white)
            Text(browser.activeSpace.name).font(.system(size: 14)).foregroundStyle(GlassPalette.secondary)
            Button {
                addressText = "https://www.google.com"
                openAddress()
            } label: {
                Label("Start browsing", systemImage: "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .background(GlassPalette.accent.opacity(0.28), in: Capsule())
                    .overlay(Capsule().stroke(GlassPalette.accent.opacity(0.45)))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var navigationBar: some View {
        HStack(spacing: 0) {
            navigationButton("chevron.left", enabled: browser.activeTab?.canGoBack == true) { browser.activeTab?.goBack() }
            Spacer()
            navigationButton("chevron.right", enabled: browser.activeTab?.canGoForward == true) { browser.activeTab?.goForward() }
            Spacer()
            navigationButton("clock.arrow.circlepath", enabled: true) { librarySection = 0; showLibrary = true }
            Spacer()
            navigationButton("arrow.clockwise", enabled: browser.activeTab?.address.isEmpty == false) { browser.activeTab?.reload() }
            Spacer()
            navigationButton("square.on.square", enabled: true) { browser.addTab() }
            Text("\(browser.tabs.count)").font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(GlassPalette.secondary).padding(.leading, 4)
        }
        .padding(.horizontal, 14).frame(height: 48)
        .background(GlassPalette.panel, in: Capsule()).overlay(Capsule().stroke(GlassPalette.line))
    }

    private var librarySheet: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Picker("Library", selection: $librarySection) {
                    Text("History").tag(0)
                    Text("Bookmarks").tag(1)
                }
                .pickerStyle(.segmented).padding(.horizontal)
                if librarySection == 0 {
                    if browser.history.isEmpty {
                        ContentUnavailableView("No history yet", systemImage: "clock", description: Text("Pages you visit will appear here."))
                    } else {
                        List {
                            ForEach(browser.history, id: \.self) { url in
                                libraryRow(title: URL(string: url)?.host ?? url, subtitle: url, symbol: "clock") { openLibraryURL(url) }
                            }
                        }.listStyle(.plain)
                    }
                } else {
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
                        }.listStyle(.plain)
                    }
                }
            }
            .padding(.top, 12).background(GlassPalette.background)
            .navigationTitle("Library").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if librarySection == 0 && !browser.history.isEmpty { Button("Clear") { browser.clearHistory() } }
                }
                ToolbarItem(placement: .topBarLeading) { Button("Done") { showLibrary = false } }
            }
        }
        .tint(GlassPalette.accent)
    }

    private var spacesSheet: some View {
        NavigationStack {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    TextField("New space name", text: $newSpaceName)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .onSubmit(addSpace)
                    Button(action: addSpace) {
                        Image(systemName: "plus").font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white).frame(width: 38, height: 38)
                            .background(GlassPalette.accent, in: Circle())
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
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(GlassPalette.accent)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            browser.selectSpace(space)
                            showSpaces = false
                        }
                        .listRowBackground(GlassPalette.panel)
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
            .padding(.top, 14).background(GlassPalette.background)
            .navigationTitle("Spaces").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { showSpaces = false } }
            }
        }
        .tint(GlassPalette.accent)
    }

    private func addSpace() {
        browser.createSpace(name: newSpaceName)
        newSpaceName = ""
        showSpaces = false
    }

    private func libraryRow(title: String, subtitle: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).foregroundStyle(GlassPalette.accent).frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 14, weight: .medium)).foregroundStyle(.white).lineLimit(1)
                    Text(subtitle).font(.system(size: 11)).foregroundStyle(GlassPalette.secondary).lineLimit(1)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(GlassPalette.panel)
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
                .foregroundStyle(enabled ? .white : GlassPalette.secondary.opacity(0.3)).frame(width: 38, height: 38)
        }
        .disabled(!enabled)
    }

    private func spaceColor(_ tint: String) -> Color {
        switch tint {
        case "blue": return Color(red: 0.30, green: 0.62, blue: 1.0)
        case "green": return Color(red: 0.28, green: 0.82, blue: 0.58)
        case "orange": return Color(red: 1.0, green: 0.62, blue: 0.30)
        default: return GlassPalette.accent
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
            var components = URLComponents(string: "https://www.google.com/search")
            components?.queryItems = [URLQueryItem(name: "q", value: input)]
            destination = components?.url
        }
        guard let destination else { return }
        tab.load(destination)
        hideKeyboard()
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
