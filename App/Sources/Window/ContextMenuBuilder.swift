import AppKit

struct ContextMenuActions {
    var openSettings: () -> Void
    var toggleMute: () -> Void
    var quit: () -> Void
}

/// Island right-click menu (also used by the status item): Settings…, mute toggle, separator, Quit.
enum ContextMenuBuilder {
    @MainActor static func menu(isMuted: Bool, actions: ContextMenuActions) -> NSMenu {
        let menu = NSMenu()
        menu.addItem(ClosureMenuItem(String(localized: "menu.settings"), key: ",", action: actions.openSettings))
        menu.addItem(
            ClosureMenuItem(
                isMuted ? String(localized: "menu.unmute") : String(localized: "menu.mute1h"), key: "",
                action: actions.toggleMute))
        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem(String(localized: "menu.quit"), key: "q", action: actions.quit))
        return menu
    }
}

/// NSMenuItem that runs a closure; it is its own target.
private final class ClosureMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(_ title: String, key: String, action handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(run), keyEquivalent: key)
        target = self
    }

    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    @objc private func run() { handler() }
}
