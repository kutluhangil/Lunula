import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = MainMenu.make(openSettings: { CompositionRoot.shared.showSettings() })
        // As the unit-test host the app must not start system services (permissions, monitors, panels).
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        CompositionRoot.shared.start()
    }

    /// `lunula://` URLs (Terminal, scripts, agent hooks). `open -g` keeps the frontmost app in front.
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls { CompositionRoot.shared.handle(url) }
    }
}

/// Shown only while Lunula is active (the settings window): ⌘, ⌘Q, editing keys for text fields and ⌘W.
@MainActor enum MainMenu {
    static func make(openSettings: @escaping @MainActor () -> Void) -> NSMenu {
        let main = NSMenu()

        let app = NSMenu()
        let settings = NSMenuItem(
            title: String(localized: "menu.settings"), action: #selector(SettingsAction.run), keyEquivalent: ",")
        let target = SettingsAction(openSettings)
        settings.target = target
        settings.representedObject = target  // the menu item keeps its target alive
        app.addItem(settings)
        app.addItem(.separator())
        app.addItem(
            NSMenuItem(
                title: String(localized: "menu.quit"), action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"))
        add(app, to: main)

        let edit = NSMenu(title: String(localized: "menu.edit"))
        edit.addItem(
            NSMenuItem(title: String(localized: "menu.cut"), action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        edit.addItem(
            NSMenuItem(title: String(localized: "menu.copy"), action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        edit.addItem(
            NSMenuItem(title: String(localized: "menu.paste"), action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        edit.addItem(
            NSMenuItem(
                title: String(localized: "menu.selectAll"), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        )
        add(edit, to: main)

        let window = NSMenu(title: String(localized: "menu.window"))
        window.addItem(
            NSMenuItem(
                title: String(localized: "menu.close"), action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"
            ))
        add(window, to: main)
        return main
    }

    private static func add(_ submenu: NSMenu, to main: NSMenu) {
        let item = NSMenuItem()
        item.submenu = submenu
        main.addItem(item)
    }
}

private final class SettingsAction: NSObject {
    private let action: @MainActor () -> Void
    init(_ action: @escaping @MainActor () -> Void) { self.action = action }
    @MainActor @objc func run() { action() }
}
