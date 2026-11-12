# GLASS architecture

## Product direction

GLASS is a browser product, not just a website that looks like a browser. The existing PWA remains the design reference and a useful companion surface. Native applications own browser-engine integration and platform capabilities.

## Platform strategy

| Platform | Rendering engine | Native shell | Notes |
|---|---|---|---|
| iPhone / iPad | Apple WebKit through WKWebView | Swift + SwiftUI | Required platform path. iOS browser-engine entitlements and regional rules can vary; do not assume Chromium can ship as an ordinary embedded engine. |
| Android | Android System WebView (Chromium/Blink) initially | Kotlin + Jetpack Compose | A system-provided Chromium-based engine; evaluate a custom Chromium build only if product requirements justify its maintenance cost. |
| Windows | Microsoft Edge WebView2 (Chromium/Blink) initially | C# + WinUI 3 | Lower maintenance than owning a Chromium fork. |
| Cloud | No page-rendering engine | TypeScript services | Account sync, encrypted settings/session metadata, device registration and sync conflict handling. |

## Shared product layer

- Design tokens: colors, typography, radii, blur and motion values.
- Browser concepts: tabs, spaces, bookmarks, history, downloads and sessions.
- Sync schema and conflict rules.
- AI provider interface. Providers must be opt-in and disclose when a paid API is used.
- Privacy and security policy shared across clients.

The native UI is implemented with platform-native components, while the shared product rules and data contracts are documented independently. This avoids forcing one web UI framework to impersonate native browser controls.

## iOS MVP scope

1. A SwiftUI app shell using the GLASS visual language.
2. One real WKWebView instance per tab.
3. Address/search input, navigation, reload and tab switching.
4. Basic local history.
5. A foundation for spaces, bookmarks, downloads and sync.

The first iOS source scaffold lives in `GLASS-iOS/App`. It is source code, not yet a signed, installable iOS app. Building and signing require Xcode on macOS and an Apple development setup.

## Important constraints

- WKWebView is Apple's supported web-content engine for an ordinary iOS app. Do not label the iOS build Chromium.
- Android System WebView and Windows WebView2 are Chromium-based, but they are not equivalent to maintaining a private Chromium fork.
- A WKWebView per tab gives independent navigation state, but tabs share the app's default website data store in this MVP.
- Password storage, private browsing, content blocking, downloads, permissions, extensions and sync require explicit security/product work before release.
- Never send browsing history, URLs or page content to cloud/AI services without a clear user-facing setting and consent.

## Delivery phases

- Phase 0: architecture and native source scaffold.
- Phase 1: working iOS browser shell and tab lifecycle.
- Phase 2: bookmarks, history UI, downloads, private mode and content controls.
- Phase 3: Android and Windows clients using their native browser components.
- Phase 4: encrypted cloud sync and account/device management.
- Phase 5: optional AI tools and advanced browser features.
