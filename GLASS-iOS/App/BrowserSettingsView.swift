import SwiftUI

struct BrowserSettingsView: View {
    @EnvironmentObject private var browser: BrowserStore
    @Environment(\.dismiss) private var dismiss
    @State private var customURL = ""
    @State private var permissionDomain = ""
    @State private var appearanceApplied = false
    @AppStorage("glass.theme.backgroundStyle") private var themeBackgroundStyle = "aurora"
    @AppStorage("glass.theme.addressOpacity") private var themeAddressOpacity = 0.075
    @AppStorage("glass.theme.cardOpacity") private var themeCardOpacity = 0.075
    @AppStorage("glass.theme.dockOpacity") private var themeDockOpacity = 0.052
    @AppStorage("glass.theme.preset") private var themePreset = "violet"
    @AppStorage("glass.theme.panelOpacity") private var themePanelOpacity = 0.075
    @AppStorage("glass.theme.glow") private var themeGlow = 0.55
    @AppStorage("glass.theme.cornerRadius") private var themeCornerRadius = 20.0
    @AppStorage("glass.theme.blur") private var themeBlur = 0.65

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.055, green: 0.05, blue: 0.085).ignoresSafeArea()
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 17) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Choose your atmosphere")
                                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("Four signature GLASS themes. The layout stays consistent; the atmosphere changes.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.55))
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                ForEach(GlassAppearance.presets, id: \.self) { preset in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            themePreset = preset
                                        }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 9) {
                                            ZStack(alignment: .bottomLeading) {
                                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                                    .fill(LinearGradient(
                                                        colors: GlassAppearance.previewColors(for: preset),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ))
                                                VStack(alignment: .leading, spacing: 7) {
                                                    HStack(spacing: 4) {
                                                        Circle().fill(.white.opacity(0.85)).frame(width: 5, height: 5)
                                                        Circle().fill(.white.opacity(0.45)).frame(width: 5, height: 5)
                                                        Circle().fill(.white.opacity(0.25)).frame(width: 5, height: 5)
                                                        Spacer()
                                                        Image(systemName: GlassAppearance.symbol(for: preset))
                                                            .font(.system(size: 10, weight: .semibold))
                                                    }
                                                    RoundedRectangle(cornerRadius: 5).fill(.white.opacity(0.20)).frame(width: 54, height: 5)
                                                    RoundedRectangle(cornerRadius: 5).fill(.white.opacity(0.11)).frame(width: 78, height: 4)
                                                    HStack(spacing: 4) {
                                                        RoundedRectangle(cornerRadius: 5).fill(.white.opacity(0.20)).frame(height: 18)
                                                        RoundedRectangle(cornerRadius: 5).fill(.white.opacity(0.12)).frame(height: 18)
                                                    }
                                                }
                                                .foregroundStyle(.white.opacity(0.9))
                                                .padding(10)
                                            }
                                            .frame(height: 88)
                                            HStack(spacing: 6) {
                                                Circle().fill(GlassAppearance.accent(for: preset)).frame(width: 8, height: 8)
                                                Text(GlassAppearance.title(for: preset))
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundStyle(.white)
                                                Spacer(minLength: 0)
                                                if themePreset == preset {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 14))
                                                        .foregroundStyle(GlassAppearance.accent(for: preset))
                                                }
                                            }
                                        }
                                        .padding(9)
                                        .background(Color.white.opacity(themePreset == preset ? 0.105 : 0.045), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 17).stroke(
                                            GlassAppearance.accent(for: preset).opacity(themePreset == preset ? 0.75 : 0.16),
                                            lineWidth: themePreset == preset ? 1.4 : 1
                                        ))
                                        .shadow(color: GlassAppearance.accent(for: preset).opacity(themePreset == preset ? 0.18 : 0), radius: 12, y: 3)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            HStack(spacing: 8) {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundStyle(GlassAppearance.accent(for: themePreset))
                                Text("Fine-tune your theme")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Button("Reset") {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        themePanelOpacity = 0.075
                                        themeBlur = 0.65
                                        themeGlow = 0.55
                                        themeCornerRadius = 20
                                    }
                                }
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(GlassAppearance.accent(for: themePreset))
                            }
                            .padding(.top, 5)

                            VStack(alignment: .leading, spacing: 13) {
                                Text("BACKGROUND")
                                    .font(.system(size: 9, weight: .bold))
                                    .tracking(1.4)
                                    .foregroundStyle(.white.opacity(0.45))
                                HStack(spacing: 7) {
                                    backgroundChoice("Aurora", value: "aurora", symbol: "sparkles")
                                    backgroundChoice("Gradient", value: "gradient", symbol: "circle.lefthalf.filled")
                                    backgroundChoice("Deep", value: "deep", symbol: "moon.fill")
                                }
                                Divider().overlay(.white.opacity(0.08))
                                Text("GLASS & LIGHT")
                                    .font(.system(size: 9, weight: .bold))
                                    .tracking(1.4)
                                    .foregroundStyle(.white.opacity(0.45))
                                appearanceSlider("Transparency", value: $themePanelOpacity, range: 0.035...0.16)
                                appearanceSlider("Glass blur", value: $themeBlur, range: 0.15...1.0)
                                appearanceSlider("Glow intensity", value: $themeGlow, range: 0...1)
                                appearanceSlider("Corner radius", value: $themeCornerRadius, range: 12...30)
                                Divider().overlay(.white.opacity(0.08))
                                Text("ELEMENT TRANSPARENCY")
                                    .font(.system(size: 9, weight: .bold))
                                    .tracking(1.4)
                                    .foregroundStyle(.white.opacity(0.45))
                                appearanceSlider("Address bar", value: $themeAddressOpacity, range: 0.02...0.20)
                                appearanceSlider("Cards & panels", value: $themeCardOpacity, range: 0.02...0.20)
                                appearanceSlider("Bottom dock", value: $themeDockOpacity, range: 0.02...0.20)
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.09)))

                            RoundedRectangle(cornerRadius: themeCornerRadius, style: .continuous)
                                .fill(LinearGradient(
                                    colors: GlassAppearance.previewColors(for: themePreset),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .overlay {
                                    HStack(spacing: 10) {
                                        Image(systemName: "circle.hexagongrid.fill")
                                            .foregroundStyle(.white)
                                            .shadow(color: .white.opacity(themeGlow), radius: 9)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("GLASS").font(.system(size: 11, weight: .bold)).tracking(1.4)
                                            Text("Live appearance preview").font(.system(size: 9)).foregroundStyle(.white.opacity(0.65))
                                        }
                                        Spacer()
                                        Image(systemName: "sparkles").foregroundStyle(.white.opacity(0.8))
                                    }
                                    .padding(14)
                                }
                                .overlay(RoundedRectangle(cornerRadius: themeCornerRadius).stroke(.white.opacity(0.18)))
                                .frame(height: 62)

                            Button {
                                appearanceApplied = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: appearanceApplied ? "checkmark" : "checkmark.circle.fill")
                                    Text(appearanceApplied ? "Применено" : "Применить")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(LinearGradient(
                                    colors: [GlassAppearance.accent(for: themePreset), GlassAppearance.accent(for: themePreset).opacity(0.68)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .shadow(color: GlassAppearance.accent(for: themePreset).opacity(0.24), radius: 12, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 10)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    } header: {
                        Text("GLASS THEMES")
                    } footer: {
                        Text("The four approved themes stay fixed. Every slider updates the browser immediately and is saved on this device.")
                    }

                    Section {
                        Picker("Search engine", selection: setting(\.searchEngine)) {
                            ForEach(GlassSearchEngine.allCases) { engine in
                                Text(engine.title).tag(engine)
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.075))
                    } header: {
                        Text("Search")
                    } footer: {
                        Text("This engine is used whenever text is entered in the address bar.")
                    }

                    Section {
                        Toggle("Block ads", isOn: setting(\.adBlockingEnabled))
                            .listRowBackground(Color.white.opacity(0.075))
                        Toggle("Block known trackers", isOn: setting(\.trackerBlockingEnabled))
                            .listRowBackground(Color.white.opacity(0.075))
                    } header: {
                        Text("Protection")
                    } footer: {
                        Text("GLASS uses WebKit content rules to block common advertising and tracking resources. Some sites may need these protections disabled.")
                    }

                    Section {
                        Toggle("Allow camera requests", isOn: setting(\.cameraAllowed))
                            .listRowBackground(Color.white.opacity(0.075))
                        Toggle("Allow microphone requests", isOn: setting(\.microphoneAllowed))
                            .listRowBackground(Color.white.opacity(0.075))
                        HStack(spacing: 8) {
                            TextField("example.com", text: $permissionDomain)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            Button("Add") {
                                browser.setSitePermission(domain: permissionDomain, camera: true, microphone: true)
                                permissionDomain = ""
                            }
                            .disabled(permissionDomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .listRowBackground(Color.white.opacity(0.075))
                        ForEach(browser.settings.sitePermissions.values.sorted { $0.domain < $1.domain }) { site in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(site.domain).font(.system(size: 13, weight: .semibold))
                                    Spacer()
                                    Button(role: .destructive) { browser.removeSitePermission(site.domain) } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                                Toggle("Camera", isOn: Binding(
                                    get: { browser.settings.sitePermissions[site.domain]?.cameraAllowed ?? true },
                                    set: { browser.setSitePermission(domain: site.domain, camera: $0, microphone: browser.settings.sitePermissions[site.domain]?.microphoneAllowed ?? true) }
                                ))
                                Toggle("Microphone", isOn: Binding(
                                    get: { browser.settings.sitePermissions[site.domain]?.microphoneAllowed ?? true },
                                    set: { browser.setSitePermission(domain: site.domain, camera: browser.settings.sitePermissions[site.domain]?.cameraAllowed ?? true, microphone: $0) }
                                ))
                            }
                            .listRowBackground(Color.white.opacity(0.075))
                        }
                        Label("Location access is controlled by iOS site and app permission prompts.", systemImage: "location")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .listRowBackground(Color.white.opacity(0.075))
                    } header: {
                        Text("Site permissions")
                    } footer: {
                        Text("Camera and microphone requests are handled by the browser delegate. iOS does not expose a general per-site geolocation permission manager to this app.")
                    }

                    Section {
                        Picker("New tab page", selection: setting(\.startPage)) {
                            Text("GLASS start page").tag("glass")
                            Text("Custom website").tag("custom")
                        }
                        .listRowBackground(Color.white.opacity(0.075))
                        if browser.settings.startPage == "custom" {
                            TextField("https://example.com", text: $customURL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                                .listRowBackground(Color.white.opacity(0.075))
                                .onChange(of: customURL) { _, value in
                                    browser.updateCustomStartPage(value)
                                }
                        }
                    } header: {
                        Text("Start page")
                    }

                    Section {
                        Toggle("Clear private data when tabs close", isOn: setting(\.clearPrivateDataOnClose))
                            .listRowBackground(Color.white.opacity(0.075))
                        Button(role: .destructive) {
                            browser.closeAllPrivateTabs()
                        } label: {
                            Label("Close all private tabs now", systemImage: "eye.slash")
                        }
                        .listRowBackground(Color.white.opacity(0.075))
                    } header: {
                        Text("Private browsing")
                    } footer: {
                        Text("Private tabs use a non-persistent WebKit data store. Closing a private tab destroys its in-memory browsing session.")
                    }

                    Section {
                        HStack {
                            Label("Cloud sync", systemImage: "icloud")
                            Spacer()
                            Text("Coming later")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .listRowBackground(Color.white.opacity(0.075))
                        Text("Local AES-GCM encryption and Keychain key storage are implemented. Cross-device sync remains off until secure device pairing, account authentication, and the Cloudflare service are connected.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .listRowBackground(Color.white.opacity(0.075))
                    } header: {
                        Text("Sync")
                    }
                }
                .scrollContentBackground(.hidden)
                .foregroundStyle(.white)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 15, weight: .semibold)) }
                }
                ToolbarItem(placement: .principal) {
                    Text("Темы").font(.system(size: 16, weight: .semibold))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Сбросить оформление", systemImage: "arrow.counterclockwise") {
                            themePreset = "violet"
                            themePanelOpacity = 0.075
                            themeBlur = 0.65
                            themeGlow = 0.55
                            themeCornerRadius = 20
                            themeBackgroundStyle = "aurora"
                            themeAddressOpacity = 0.075
                            themeCardOpacity = 0.075
                            themeDockOpacity = 0.052
                            appearanceApplied = false
                        }
                    } label: {
                        Image(systemName: "ellipsis").font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .onAppear {
                customURL = browser.settings.customStartPageURL
            }
        }
        .tint(Color(red: 0.68, green: 0.53, blue: 1.0))
        .preferredColorScheme(.dark)
    }

    private func backgroundChoice(_ title: String, value: String, symbol: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                themeBackgroundStyle = value
                appearanceApplied = false
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 13, weight: .semibold))
                Text(title).font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(themeBackgroundStyle == value ? .white : .white.opacity(0.55))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                themeBackgroundStyle == value
                    ? GlassAppearance.accent(for: themePreset).opacity(0.26)
                    : Color.white.opacity(0.045),
                in: RoundedRectangle(cornerRadius: 11, style: .continuous)
            )
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(
                themeBackgroundStyle == value ? GlassAppearance.accent(for: themePreset).opacity(0.65) : .white.opacity(0.08)
            ))
        }
        .buttonStyle(.plain)
    }

    private func appearanceSlider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.system(size: 12, weight: .medium))
                Spacer()
                Text(title == "Corner radius" ? "\(Int(value.wrappedValue)) pt" : "\(Int(value.wrappedValue * 100))%")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
                .tint(GlassAppearance.accent(for: themePreset))
        }
    }

    private func setting<Value>(_ keyPath: WritableKeyPath<GlassBrowserSettings, Value>) -> Binding<Value> {
        Binding(
            get: { browser.settings[keyPath: keyPath] },
            set: { browser.updateSetting(keyPath, value: $0) }
        )
    }
}
