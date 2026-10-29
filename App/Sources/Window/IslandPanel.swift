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

    /// A pointer resting on the screen's top edge lands exactly on the panel's top boundary (y == height), which
    /// SwiftUI hit testing excludes; nudge such clicks one point inside so the island still receives them.
    override func sendEvent(_ event: NSEvent) {
        let clicks: [NSEvent.EventType] = [.leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp]
        guard clicks.contains(event.type), event.locationInWindow.y >= frame.height,
            let nudged = NSEvent.mouseEvent(
                with: event.type, location: NSPoint(x: event.locationInWindow.x, y: frame.height - 1),
                modifierFlags: event.modifierFlags, timestamp: event.timestamp, windowNumber: event.windowNumber,
                context: nil, eventNumber: event.eventNumber, clickCount: event.clickCount, pressure: event.pressure)
        else { return super.sendEvent(event) }
        super.sendEvent(nudged)
    }

    override var canBecomeKey: Bool { allowsKey }
    override var canBecomeMain: Bool { false }
}
