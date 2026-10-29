import AppKit
import IslandCore
import IslandCoreTestSupport
import Testing

@testable import Lunula

@MainActor @Suite struct PointerRouterTests {
    @Test func hotZoneEventsForwardedOnlyWhileResting() {
        var sent: [IslandEvent] = []
        var phase = IslandPhase.idle
        let r = PointerRouter(
            send: { sent.append($0) }, phase: { phase }, geometry: { (.zero, []) }, showContextMenu: { _ in })
        r.hotZoneEntered()
        phase = .expanded(.home)
        r.hotZoneExited()
        #expect(sent == [.pointerEnteredHotZone])
    }

    @Test func islandHoverForwardedOnlyWhileOpen() {
        var sent: [IslandEvent] = []
        var phase = IslandPhase.peek
        let r = PointerRouter(
            send: { sent.append($0) }, phase: { phase }, geometry: { (.zero, []) }, showContextMenu: { _ in })
        r.islandHoverChanged(false)
        phase = .idle
        r.islandHoverChanged(true)
        #expect(sent == [.pointerExitedIsland])
    }

    @Test func islandHoverReentryIsForwardedWhileOpen() {
        var sent: [IslandEvent] = []
        let r = PointerRouter(
            send: { sent.append($0) }, phase: { .expanded(.home) }, geometry: { (.zero, []) }, showContextMenu: { _ in }
        )
        r.islandHoverChanged(false)
        r.islandHoverChanged(true)
        #expect(sent == [.pointerExitedIsland, .pointerEnteredHotZone])
    }

    @Test func rightClickOpensContextMenu() {
        var opened = false
        let r = PointerRouter(
            send: { _ in }, phase: { .idle }, geometry: { (.zero, []) }, showContextMenu: { _ in opened = true })
        r.hotZoneClicked(at: .zero, button: .right)
        #expect(opened)
    }
}
