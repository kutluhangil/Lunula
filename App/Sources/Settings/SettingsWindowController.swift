import AppKit
import SwiftUI

/// Toolbar-style preferences window: one NSHostingController per tab.
@MainActor final class SettingsWindowController: NSWindowController {
    init(tabs: [SettingsTab]) {
        let tabController = NSTabViewController()
        tabController.tabStyle = .toolbar
        for tab in tabs {
            let item = NSTabViewItem(viewController: NSHostingController(rootView: tab.makeView()))
            item.identifier = tab.id
            item.label = String(localized: tab.titleKey)
            item.image = NSImage(systemSymbolName: tab.symbol, accessibilityDescription: nil)
            tabController.addTabViewItem(item)
        }
        let window = NSWindow(contentViewController: tabController)
        window.styleMask = [.titled, .closable]
        window.toolbarStyle = .preference
        window.isReleasedWhenClosed = false
        window.center()
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func show() {
        NSApp.activate()
        window?.center()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}
