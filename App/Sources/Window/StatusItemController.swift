import AppKit
import SwiftUI

/// Optional menu bar icon; its menu is the island's context menu, and it can also host a detached tools popover.
@MainActor final class StatusItemController: NSObject, NSMenuDelegate {
    private let menu: @MainActor () -> NSMenu
    private var item: NSStatusItem?
    private var popover: NSPopover?

    init(menu: @escaping @MainActor () -> NSMenu) { self.menu = menu }

    var isVisible: Bool {
        get { item != nil }
        set {
            guard newValue != isVisible else { return }
            if newValue {
                let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
                item.button?.image = NSImage(
                    systemSymbolName: "capsule.fill", accessibilityDescription: String(localized: "app.name"))
                let placeholder = NSMenu()
                placeholder.delegate = self
                item.menu = placeholder
                self.item = item
            } else if let item {
                popover?.performClose(nil)
                popover = nil
                NSStatusBar.system.removeStatusItem(item)
                self.item = nil
            }
        }
    }

    func togglePopover(rootView: AnyView) {
        if !isVisible { isVisible = true }
        guard let button = item?.button else { return }
        if let popover, popover.isShown {
            popover.performClose(nil)
            return
        }
        let pop = NSPopover()
        pop.behavior = .transient
        pop.appearance = NSAppearance(named: .darkAqua)
        pop.contentViewController = NSHostingController(rootView: rootView)
        pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover = pop
    }

    func menuNeedsUpdate(_ target: NSMenu) {
        let fresh = menu()
        target.removeAllItems()
        for entry in fresh.items {
            fresh.removeItem(entry)
            target.addItem(entry)
        }
    }
}
