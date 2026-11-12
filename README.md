# GLASS

GLASS is a personal, mobile-first browser experience with a Liquid Glass-inspired interface.

## Current foundation
- Responsive home screen and floating navigation dock
- Unified web search entry point
- Workspace cards for Gaming, Work, and Shopping
- Accent presets and adjustable glass opacity, blur, and radius
- Shortcut creation and speech-recognition hook
- Installable PWA shell with a basic service worker

## Next implementation stages
1. Match the supplied home-screen and theme-settings references precisely.
2. Build real tab, group, bookmark, history, and session management.
3. Add secure cloud sync across devices.
4. Implement native browser shells for iOS, Android, and desktop.

## Platform scope
This repository currently contains the web/PWA interface foundation. A PWA is not a full browser engine and cannot replace the native browser engine on iOS. Native browser capabilities, real tab/session management, and cross-device sync require subsequent platform-specific implementation.

## Run locally
Serve this directory over HTTPS or localhost. The service worker is registered automatically where supported.


## Native browser development

The native architecture and current platform choices are documented in [ARCHITECTURE.md](ARCHITECTURE.md). The first iOS SwiftUI + WebKit source scaffold is in [GLASS-iOS](GLASS-iOS/README.md).

The native iOS project uses XcodeGen. On a Mac with Xcode and XcodeGen installed:

```sh
cd GLASS-iOS
xcodegen generate
open GLASS-iOS.xcodeproj
```

This generates the Xcode project from `GLASS-iOS/project.yml`. The iOS app is not yet signed, built, or distributed.
