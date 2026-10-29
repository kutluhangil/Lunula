import AppKit

/// Optional menu bar icon; its menu is the island's context menu, rebuilt on every open so titles stay current.
@MainActor final class StatusItemController: NSObject, NSMenuDelegate {
    private let menu: @MainActor () -> NSMenu
    private var item: NSStatusItem?

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
                NSStatusBar.system.removeStatusItem(item)
                self.item = nil
            }
        }
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
