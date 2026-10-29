import AppKit

enum HotZoneButton { case left, right }

@MainActor protocol HotZoneDelegate: AnyObject {
    func hotZoneEntered()
    func hotZoneExited()
    func hotZoneMoved(to: NSPoint, at: TimeInterval)
    func hotZoneClicked(at: NSPoint, button: HotZoneButton)
    func hotZoneScrolled(deltaY: CGFloat, phase: NSEvent.Phase, momentumPhase: NSEvent.Phase, inverted: Bool)
}

/// Forwards pointer events to its delegate with points in screen coordinates.
final class HotZoneView: NSView {
    weak var delegate: HotZoneDelegate?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addTrackingArea(
            NSTrackingArea(
                rect: .zero, options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
                owner: self))
    }

    convenience init() { self.init(frame: .zero) }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseEntered(with event: NSEvent) { delegate?.hotZoneEntered() }
    override func mouseExited(with event: NSEvent) { delegate?.hotZoneExited() }

    override func mouseMoved(with event: NSEvent) {
        delegate?.hotZoneMoved(to: screenPoint(event), at: event.timestamp)
    }

    override func mouseDown(with event: NSEvent) {
        delegate?.hotZoneClicked(at: screenPoint(event), button: .left)
    }

    override func rightMouseDown(with event: NSEvent) {
        delegate?.hotZoneClicked(at: screenPoint(event), button: .right)
    }

    override func scrollWheel(with event: NSEvent) {
        delegate?.hotZoneScrolled(
            deltaY: event.scrollingDeltaY, phase: event.phase, momentumPhase: event.momentumPhase,
            inverted: event.isDirectionInvertedFromDevice)
    }

    private func screenPoint(_ event: NSEvent) -> NSPoint {
        window?.convertPoint(toScreen: event.locationInWindow) ?? event.locationInWindow
    }
}
