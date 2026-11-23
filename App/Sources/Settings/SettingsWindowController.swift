import AppKit
import IslandCore
import IslandDesign
import IslandServices
import SwiftUI

/// Window controller for the unified 680 × 540 pt Lunula settings window.
@MainActor public final class SettingsWindowController: NSWindowController {
    public let settingsStore: SettingsStore?
    public let tabs: [SettingsTab]

    public init(
        settings: SettingsStore,
        launchAtLogin: LaunchAtLoginService,
        permission: @escaping @MainActor (IslandFeature) -> PermissionState? = { _ in nil },
        request: @escaping @MainActor (IslandFeature) -> Void = { _ in },
        searchWeatherCity: @escaping @MainActor (String) async -> [GeoPlace] = { _ in [] }
    ) {
        self.settingsStore = settings
        self.tabs = SettingsTab.allTabs(
            settings: settings,
            launchAtLogin: launchAtLogin,
            permission: permission,
            request: request,
            searchWeatherCity: searchWeatherCity
        )

        let rootView = SettingsWindowView(
            settings: settings,
            launchAtLogin: launchAtLogin,
            permission: permission,
            request: request,
            searchWeatherCity: searchWeatherCity
        )
        let hosting = NSHostingController(rootView: rootView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 540),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = String(localized: "settings.window.title")
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(Palette.basalt)
        window.isReleasedWhenClosed = false
        window.contentViewController = hosting
        window.setContentSize(NSSize(width: 680, height: 540))
        window.center()

        super.init(window: window)
    }

    /// Convenience initializer supporting explicit tab arrays.
    public convenience init(tabs: [SettingsTab]) {
        let dummySettings = SettingsStore(
            defaults: UserDefaults(suiteName: "lunula.settings.preview.\(UUID().uuidString)")!)
        let dummyLogin = LaunchAtLoginService()
        self.init(settings: dummySettings, launchAtLogin: dummyLogin)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public func show() {
        NSApp.activate()
        window?.center()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}
