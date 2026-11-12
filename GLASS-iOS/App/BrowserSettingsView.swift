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
    @AppStorage("glass.theme.iconStyle") private var themeIconStyle = "soft"
    @AppStorage("glass.theme.motion") private var themeMotion = 0.65
    @AppStorage("glass.theme.preset") private var themePreset = "violet"
    @AppStorage("glass.theme.panelOpacity") private var themePanelOpacity = 0.075
    @AppStorage("glass.theme.glow") private var themeGlow = 0.55
    @AppStorage("glass.theme.cornerRadius") private var themeCornerRadius = 20.0
    @AppStorage("glass.theme.blur") private var themeBlur = 0.65

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.035, green: 0.035, blue: 0.065).ignoresSafeArea()
                RadialGradient(colors: [GlassAppearance.accent(for: themePreset).opacity(0.20), .clear], center: .top, startRadius: 8, endRadius: 480).ignoresSafeArea()
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 17) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Выберите атмосферу")
                                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("Четыре фирменные темы GLASS. Структура интерфейса остаётся единой, меняется атмосфера.")
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
                                Text("Настройте тему")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Button("Сбросить") {
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
                                Text("ФОН")
                                    .font(.system(size: 9, weight: .bold))
                                    .tracking(1.4)
                                    .foregroundStyle(.white.opacity(0.45))
                                HStack(spacing: 7) {
                                    backgroundChoice("Aurora", value: "aurora", symbol: "sparkles")
                                    backgroundChoice("Gradient", value: "gradient", symbol: "circle.lefthalf.filled")
                                    backgroundChoice("Deep", value: "deep", symbol: "moon.fill")
                                }
                                Divider().overlay(.white.opacity(0.08))
                                Text("СТЕКЛО И СВЕТ")
                                    .font(.system(size: 9, weight: .bold))
                                    .tracking(1.4)
                                    .foregroundStyle(.white.opacity(0.45))
                                appearanceSlider("Transparency", value: $themePanelOpacity, range: 0.035...0.16)
                                appearanceSlider("Glass blur", value: $themeBlur, range: 0.15...1.0)
                                appearanceSlider("Glow intensity", value: $themeGlow, range: 0...1)
                                appearanceSlider("Corner radius", value: $themeCornerRadius, range: 12...30)
                                Divider().overlay(.white.opacity(0.08))
                                Text("ПРОЗРАЧНОСТЬ ЭЛЕМЕНТОВ")
                                    .font(.system(size: 9, weight: .bold))
                                    .tracking(1.4)
                                    .foregroundStyle(.white.opacity(0.45))
                                appearanceSlider("Address bar", value: $themeAddressOpacity, range: 0.02...0.20)
                                appearanceSlider("Cards & panels", value: $themeCardOpacity, range: 0.02...0.20)
                                appearanceSlider("Bottom dock", value: $themeDockOpacity, range: 0.02...0.20)
                                Divider().overlay(.white.opacity(0.08))
                                Text("ДЕТАЛИ")
                                    .font(.system(size: 9, weight: .bold))
                                    .tracking(1.4)
                                    .foregroundStyle(.white.opacity(0.45))
                                HStack {
                                    Text("Стиль значков").font(.system(size: 12, weight: .medium))
                                    Spacer()
                                    Picker("Icon weight", selection: $themeIconStyle) {
                                        Text("Мягкий").tag("soft")
                                        Text("Выразительный").tag("bold")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 142)
                                }
                                appearanceSlider("Motion intensity", value: $themeMotion, range: 0...1)
                            }
                            .padding(14)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 17).fill(Color.white.opacity(themeCardOpacity)))
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
                                            Text("Предпросмотр оформления").font(.system(size: 9)).foregroundStyle(.white.opacity(0.65))
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
                        Text("ТЕМЫ GLASS")
                    } footer: {
                        Text("Четыре основные темы остаются неизменными. Каждый ползунок сразу меняет оформление браузера, настройки сохраняются на устройстве.")
                    }

                    Section {
                        Picker("Search engine", selection: setting(\.searchEngine)) {
                            ForEach(GlassSearchEngine.allCases) { engine in
                                Text(engine.title).tag(engine)
                            }
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                        )
                    } header: {
                        Text("Поиск")
                    } footer: {
                        Text("Эта поисковая система используется при вводе текста в адресную строку.")
                    }

                    Section {
                        Toggle("Block ads", isOn: setting(\.adBlockingEnabled))
                            .listRowBackground(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                        )
                        Toggle("Block known trackers", isOn: setting(\.trackerBlockingEnabled))
                            .listRowBackground(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                        )
                    } header: {
                        Text("Защита")
                    } footer: {
                        Text("GLASS блокирует распространённые рекламные и следящие ресурсы средствами WebKit. Для работы некоторых сайтов защиту может потребоваться отключить.")
                    }

                    Section {
                        Toggle("Allow camera requests", isOn: setting(\.cameraAllowed))
                            .listRowBackground(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                        )
                        Toggle("Allow microphone requests", isOn: setting(\.microphoneAllowed))
                            .listRowBackground(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                        )
                        HStack(spacing: 8) {
                            TextField("пример.рф", text: $permissionDomain)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            Button("Добавить") {
                                browser.setSitePermission(domain: permissionDomain, camera: true, microphone: true)
                                permissionDomain = ""
                            }
                            .disabled(permissionDomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                        )
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
                            .listRowBackground(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                        )
                        }
                        Label("Доступ к геопозиции регулируется запросами разрешений iOS.", systemImage: "location")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .listRowBackground(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                        )
                    } header: {
                        Text("Разрешения сайтов")
                    } footer: {
                        Text("Запросы камеры и микрофона обрабатываются браузером. iOS не предоставляет приложению общего менеджера разрешений на геопозицию для каждого сайта.")
                    }

                    Section {
                        Picker("New tab page", selection: setting(\.startPage)) {
                            Text("Стартовая страница GLASS").tag("glass")
                            Text("Другой сайт").tag("custom")
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                        )
                        if browser.settings.startPage == "custom" {
                            TextField("https://example.com", text: $customURL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                                .listRowBackground(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                        )
                                .onChange(of: customURL) { _, value in
                                    browser.updateCustomStartPage(value)
                                }
                        }
                    } header: {
                        Text("Стартовая страница")
                    }

                    Section {
                        Toggle("Clear private data when tabs close", isOn: setting(\.clearPrivateDataOnClose))
                            .listRowBackground(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                        )
                        Button(role: .destructive) {
                            browser.closeAllPrivateTabs()
                        } label: {
                            Label("Закрыть все приватные вкладки" , systemImage: "eye.slash")
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                        )
                    } header: {
                        Text("Приватный режим")
                    } footer: {
                        Text("Приватные вкладки используют временное хранилище WebKit. При закрытии вкладки её данные сеанса удаляются.")
                    }

                    Section {
                        HStack {
                            Label("Облачная синхронизация", systemImage: "icloud")
                            Spacer()
                            Text("Позже")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                        )
                        Text("Локальное шифрование AES-GCM и хранение ключа в Keychain уже реализованы. Синхронизация между устройствами появится после подключения безопасного сопряжения, авторизации и сервиса Cloudflare.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .listRowBackground(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(themeCardOpacity * 0.55)))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.075), lineWidth: 0.8))
                        )
                    } header: {
                        Text("Синхронизация")
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .listRowSeparatorTint(Color.white.opacity(0.075))
                .environment(\.defaultMinListRowHeight, 48)
                .foregroundStyle(.white)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 15, weight: .semibold)) }
                }
                ToolbarItem(placement: .principal) {
                    Text("Настройки").font(.system(size: 16, weight: .semibold))
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
                            themeIconStyle = "soft"
                            themeMotion = 0.65
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
        .tint(GlassAppearance.accent(for: themePreset))
        .toolbarBackground(.hidden, for: .navigationBar)
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
