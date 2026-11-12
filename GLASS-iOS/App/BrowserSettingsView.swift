import SwiftUI

struct BrowserSettingsView: View {
    @EnvironmentObject private var browser: BrowserStore
    @Environment(\.dismiss) private var dismiss
    @State private var customURL = ""
    @State private var permissionDomain = ""
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
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("GLASS appearance").font(.system(size: 15, weight: .semibold))
                                    Text("One visual language across the browser").font(.system(size: 11)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: GlassAppearance.symbol(for: themePreset))
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(GlassAppearance.accent(for: themePreset))
                            }
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                                ForEach(GlassAppearance.presets, id: \.self) { preset in
                                    Button {
                                        themePreset = preset
                                    } label: {
                                        HStack(spacing: 8) {
                                            Circle().fill(GlassAppearance.accent(for: preset)).frame(width: 12, height: 12)
                                            Text(GlassAppearance.title(for: preset)).font(.system(size: 12, weight: .semibold))
                                            Spacer()
                                            if themePreset == preset {
                                                Image(systemName: "checkmark.circle.fill").font(.system(size: 13))
                                            }
                                        }
                                        .foregroundStyle(.white)
                                        .padding(11)
                                        .background(GlassAppearance.accent(for: preset).opacity(themePreset == preset ? 0.22 : 0.09), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(GlassAppearance.accent(for: preset).opacity(themePreset == preset ? 0.65 : 0.20)))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            VStack(spacing: 12) {
                                appearanceSlider("Transparency", value: $themePanelOpacity, range: 0.035...0.16)
                                appearanceSlider("Blur", value: $themeBlur, range: 0.15...1.0)
                                appearanceSlider("Glow", value: $themeGlow, range: 0...1)
                                appearanceSlider("Corner radius", value: $themeCornerRadius, range: 12...30)
                            }
                            .padding(.top, 3)
                            RoundedRectangle(cornerRadius: themeCornerRadius, style: .continuous)
                                .fill(GlassAppearance.accent(for: themePreset).opacity(0.15))
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: themeCornerRadius, style: .continuous))
                                .overlay {
                                    HStack {
                                        Image(systemName: "circle.hexagongrid.fill")
                                            .foregroundStyle(GlassAppearance.accent(for: themePreset))
                                            .shadow(color: GlassAppearance.accent(for: themePreset).opacity(themeGlow), radius: 10)
                                        Text("Live GLASS preview").font(.system(size: 12, weight: .semibold))
                                        Spacer()
                                        Image(systemName: "arrow.up.right").font(.system(size: 10))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(14)
                                }
                                .frame(height: 54)
                        }
                        .padding(.vertical, 7)
                        .listRowBackground(Color.white.opacity(0.045))
                    } header: {
                        Text("Appearance")
                    } footer: {
                        Text("Your appearance is saved on this device. The same preset and controls will be included in secure sync once device pairing is connected.")
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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                customURL = browser.settings.customStartPageURL
            }
        }
        .tint(Color(red: 0.68, green: 0.53, blue: 1.0))
        .preferredColorScheme(.dark)
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
