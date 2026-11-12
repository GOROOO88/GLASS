import SwiftUI

struct BrowserSettingsView: View {
    @EnvironmentObject private var browser: BrowserStore
    @Environment(\.dismiss) private var dismiss
    @State private var customURL = ""
    @State private var permissionDomain = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.055, green: 0.05, blue: 0.085).ignoresSafeArea()
                List {
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
                        HStack(spacing: 8) {\n                            TextField("example.com", text: $permissionDomain)\n                                .textInputAutocapitalization(.never)\n                                .autocorrectionDisabled()\n                            Button("Add") {\n                                browser.setSitePermission(domain: permissionDomain, camera: true, microphone: true)\n                                permissionDomain = ""\n                            }\n                            .disabled(permissionDomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)\n                        }\n                        .listRowBackground(Color.white.opacity(0.075))\n                        ForEach(browser.settings.sitePermissions.values.sorted { $0.domain < $1.domain }) { site in\n                            VStack(alignment: .leading, spacing: 8) {\n                                HStack {\n                                    Text(site.domain).font(.system(size: 13, weight: .semibold))\n                                    Spacer()\n                                    Button(role: .destructive) { browser.removeSitePermission(site.domain) } label: {\n                                        Image(systemName: "trash")\n                                    }\n                                }\n                                Toggle("Camera", isOn: Binding(\n                                    get: { browser.settings.sitePermissions[site.domain]?.cameraAllowed ?? true },\n                                    set: { browser.setSitePermission(domain: site.domain, camera: $0, microphone: browser.settings.sitePermissions[site.domain]?.microphoneAllowed ?? true) }\n                                ))\n                                Toggle("Microphone", isOn: Binding(\n                                    get: { browser.settings.sitePermissions[site.domain]?.microphoneAllowed ?? true },\n                                    set: { browser.setSitePermission(domain: site.domain, camera: browser.settings.sitePermissions[site.domain]?.cameraAllowed ?? true, microphone: $0) }\n                                ))\n                            }\n                            .listRowBackground(Color.white.opacity(0.075))\n                        }\n                        Label("Location access is controlled by iOS site and app permission prompts.", systemImage: "location")
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
                        Text("Settings are currently saved on this device. Cross-device sync needs a configured secure GLASS account and Cloudflare sync service.")
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

    private func setting<Value>(_ keyPath: WritableKeyPath<GlassBrowserSettings, Value>) -> Binding<Value> {
        Binding(
            get: { browser.settings[keyPath: keyPath] },
            set: { browser.updateSetting(keyPath, value: $0) }
        )
    }
}
