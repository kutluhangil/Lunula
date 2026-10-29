import AppKit
import IslandCore

/// Turns hot-zone pointer events into island events. While the island is open (peek/expanded) it is larger than
/// the hot zone, so enter/exit come from the island view's own hover instead (`islandHoverChanged`).
@MainActor final class PointerRouter: HotZoneDelegate {
    private let send: @MainActor (IslandEvent) -> Void
    private let phase: @MainActor () -> IslandPhase
    private let geometry: @MainActor () -> (island: CGRect, bubbles: [(ActivityID, CGRect)])
    private let showContextMenu: @MainActor (NSPoint) -> Void
    private var speedEstimator = PointerSpeedEstimator()
    private var swipe = SwipeDetector()
    private var lastMoveTime: TimeInterval = 0

    init(
        send: @escaping @MainActor (IslandEvent) -> Void, phase: @escaping @MainActor () -> IslandPhase,
        geometry: @escaping @MainActor () -> (island: CGRect, bubbles: [(ActivityID, CGRect)]),
        showContextMenu: @escaping @MainActor (NSPoint) -> Void
    ) {
        self.send = send
        self.phase = phase
        self.geometry = geometry
        self.showContextMenu = showContextMenu
    }

    var currentSpeed: Double { speedEstimator.speed(at: lastMoveTime) }

    func islandHoverChanged(_ inside: Bool) {
        guard !isResting else { return }
        // Re-entry within the exit grace cancels the pending collapse (reducer: pointerInside + cancel exitGrace).
        send(inside ? .pointerEnteredHotZone : .pointerExitedIsland)
    }

    func hotZoneEntered() {
        guard isResting else { return }
        send(.pointerEnteredHotZone)
    }

    func hotZoneExited() {
        guard isResting else { return }
        send(.pointerExitedIsland)
    }

    func hotZoneMoved(to point: NSPoint, at time: TimeInterval) {
        lastMoveTime = time
        speedEstimator.add(point, at: time)
    }

    func hotZoneClicked(at point: NSPoint, button: HotZoneButton) {
        switch button {
        case .right:
            showContextMenu(point)
        case .left:
            guard isResting else { return }
            let g = geometry()
            // The hot zone is slightly larger than the closed island; a click anywhere in it means the island.
            send(.clicked(IslandHitTesting.target(at: point, island: g.island, bubbles: g.bubbles) ?? .island))
        }
    }

    func hotZoneScrolled(deltaY: CGFloat, phase eventPhase: NSEvent.Phase, momentumPhase: NSEvent.Phase, inverted: Bool)
    {
        let scrollPhase: ScrollPhase =
            if eventPhase.contains(.began) {
                .began
            } else if eventPhase.contains(.changed) {
                .changed
            } else if eventPhase.contains(.ended) || eventPhase.contains(.cancelled) {
                .ended
            } else {
                .none
            }
        switch swipe.feed(deltaY: deltaY, phase: scrollPhase, isMomentum: !momentumPhase.isEmpty, inverted: inverted) {
        case .down: send(.swipedDown)
        case .up: send(.swipedUp)
        case nil: break
        }
    }

    private var isResting: Bool {
        switch phase() {
        case .idle, .compact, .transient: true
        case .hidden, .peek, .expanded: false
        }
    }
}
