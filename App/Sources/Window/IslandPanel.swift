import AppKit

/// Spec §4.1 panel configuration shared by the island and its hot zone.
@MainActor func configureIslandPanel(_ panel: NSPanel) {
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    panel.isMovable = false
    panel.hidesOnDeactivate = false
    panel.isFloatingPanel = true
    // After isFloatingPanel, which resets the level to .floating.
    panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 8)
    panel.animationBehavior = .none
    panel.isReleasedWhenClosed = false
}

final class IslandPanel: NSPanel {
    var allowsKey = false

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        configureIslandPanel(self)
        ignoresMouseEvents = true
    }

    override var canBecomeKey: Bool { allowsKey }
    override var canBecomeMain: Bool { false }
}
