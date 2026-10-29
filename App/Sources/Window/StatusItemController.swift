import AppKit

/// Optional menu bar icon; its menu is the island's context menu.
@MainActor final class StatusItemController {
    private let menu: @MainActor () -> NSMenu
    private var item: NSStatusItem?

    init(menu: @escaping @MainActor () -> NSMenu) { self.menu = menu }

    var isVisible: Bool {
        get { item != nil }
        set {
            guard newValue != isVisible else { return }
            if newValue {
                let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
                item.button?.image = NSImage(systemSymbolName: "capsule.fill", accessibilityDescription: "Lunula")
                item.menu = menu()
                self.item = item
            } else if let item {
                NSStatusBar.system.removeStatusItem(item)
                self.item = nil
            }
        }
    }

    /// Rebuilds the menu, e.g. after the mute state changes.
    func refreshMenu() { item?.menu = menu() }
}
