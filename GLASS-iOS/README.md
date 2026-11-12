# GLASS iOS

This folder contains the first native iOS source scaffold.

## Stack
- SwiftUI for the application shell.
- WKWebView (WebKit) for actual web page rendering.
- One WKWebView instance per open tab.
- Local-only history in UserDefaults for this first MVP.

## Current source
- `App/GLASSApp.swift`: app entry point.
- `App/BrowserTab.swift`: tab model and WKNavigationDelegate.
- `App/BrowserStore.swift`: tab lifecycle and local history.
- `App/BrowserView.swift`: WKWebView SwiftUI bridge.
- `App/ContentView.swift`: GLASS-styled browser shell.

## Build status
These are starter Swift sources, not a signed app or an Xcode project yet. To compile and install on an iPhone, the next build step must create/open an Xcode iOS app project on macOS, set the bundle identifier, choose a signing team and build to a device. This repository update does not publish or install an app.

The MVP deliberately uses WKWebView on iOS. Android and Windows will receive separate native clients using Android System WebView and WebView2 respectively.
