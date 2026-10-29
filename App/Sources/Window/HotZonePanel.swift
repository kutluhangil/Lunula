import AppKit

/// Always-mouse-enabled strip around the notch; the island panel above it ignores the mouse while closed.
final class HotZonePanel: NSPanel {
    let hotZoneView = HotZoneView()

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        configureIslandPanel(self)
        ignoresMouseEvents = false
        contentView = hotZoneView
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
