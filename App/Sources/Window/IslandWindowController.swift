import AppKit
import IslandCore
import SwiftUI

@MainActor final class IslandWindowController {
    let screenID: UInt32
    let panel: IslandPanel
    let hotZone: HotZonePanel
    let container: IslandContainerView
    private let host: NSHostingView<AnyView>
    private var resignKeyObserver: NSObjectProtocol?

    /// Scroll gestures over the open island (the hot zone is covered then); swipe up closes it.
    var scrollDelegate: HotZoneDelegate? {
        get { container.scrollDelegate }
        set { container.scrollDelegate = newValue }
    }

    /// Called when the key island panel loses key status, i.e. the user clicked outside it.
    var onResignKey: (@MainActor () -> Void)?

    init(screen: ScreenDescriptor, content: AnyView) {
        screenID = screen.id
        let notch = NotchGeometry.metrics(for: screen)
        let frame = IslandMetrics.panelFrame(notch: notch, screen: screen)
        panel = IslandPanel(contentRect: frame)
        hotZone = HotZonePanel(contentRect: IslandMetrics.hotZone(around: notch.rect, screenTop: screen.frame.maxY))

        // A bare NSHostingView contentView collapses the panel to its (empty) content size; keep a fixed container.
        container = IslandContainerView(frame: NSRect(origin: .zero, size: frame.size))
        host = NSHostingView(rootView: content)
        host.sizingOptions = []
        host.frame = container.bounds
        host.autoresizingMask = [.width, .height]
        container.addSubview(host)
        panel.contentView = container

        resignKeyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification, object: panel, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.onResignKey?() }
        }

        layout(screen: screen, hotZoneRect: IslandMetrics.hotZone(around: notch.rect, screenTop: screen.frame.maxY))
        hotZone.orderFrontRegardless()
        panel.orderFrontRegardless()
    }

    func layout(screen: ScreenDescriptor, hotZoneRect: CGRect) {
        let notch = NotchGeometry.metrics(for: screen)
        panel.setFrame(IslandMetrics.panelFrame(notch: notch, screen: screen), display: false)
        hotZone.setFrame(hotZoneRect, display: false)
        if panel.isVisible { hotZone.order(.below, relativeTo: panel.windowNumber) }
    }

    /// Swaps the SwiftUI root, e.g. when the notch geometry of this display changed.
    func setContent(_ content: AnyView) { host.rootView = content }

    func close() {
        if let resignKeyObserver { NotificationCenter.default.removeObserver(resignKeyObserver) }
        resignKeyObserver = nil
        hotZone.close()
        panel.close()
    }
}

extension IslandWindowController: PanelControlling {
    func setMouseEventsIgnored(_ ignored: Bool) { panel.ignoresMouseEvents = ignored }

    /// The panel is non-activating: it takes key focus without activating Lunula, so the frontmost app keeps
    /// focus when the island closes and our own activation never reaches the fullscreen monitor.
    func makeKey(_ key: Bool) {
        if key {
            panel.allowsKey = true
            panel.makeKeyAndOrderFront(nil)
        } else {
            panel.allowsKey = false
            panel.resignKey()
        }
    }
}

/// Fixed-size panel content; tracks hover against the island's region and forwards scroll events SwiftUI leaves
/// unhandled to the pointer router.
final class IslandContainerView: NSView {
    weak var scrollDelegate: HotZoneDelegate?
    /// Panel-local rects with a top-left origin (IslandRootView.hoverRegion).
    var hoverRegion: (@MainActor () -> [CGRect])?
    var onHoverChange: (@MainActor (Bool) -> Void)?
    private var isInside = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addTrackingArea(
            NSTrackingArea(
                rect: .zero, options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
                owner: self))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func mouseEntered(with event: NSEvent) { updateHover(event) }
    override func mouseMoved(with event: NSEvent) { updateHover(event) }
    override func mouseExited(with event: NSEvent) { updateHover(event) }

    private func updateHover(_ event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        let point = CGPoint(x: p.x, y: bounds.height - p.y)
        let inside = hoverRegion?().contains { $0.contains(point) } ?? false
        guard inside != isInside else { return }
        isInside = inside
        onHoverChange?(inside)
    }

    override func scrollWheel(with event: NSEvent) {
        guard let scrollDelegate else { return super.scrollWheel(with: event) }
        scrollDelegate.hotZoneScrolled(
            deltaY: event.scrollingDeltaY, phase: event.phase, momentumPhase: event.momentumPhase,
            inverted: event.isDirectionInvertedFromDevice)
    }
}
