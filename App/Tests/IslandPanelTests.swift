import AppKit
import IslandCore
import IslandCoreTestSupport
import SwiftUI
import Testing

@testable import Lunula

@MainActor @Suite struct IslandPanelTests {
    @Test func panelIsBorderlessNonActivatingAndClear() {
        let p = IslandPanel(contentRect: .init(x: 0, y: 0, width: 760, height: 300))
        #expect(p.styleMask.contains(.borderless) && p.styleMask.contains(.nonactivatingPanel))
        #expect(!p.isOpaque && p.backgroundColor == .clear && !p.hasShadow)
    }

    @Test func panelJoinsAllSpacesAndFullscreen() {
        let b = IslandPanel(contentRect: .zero).collectionBehavior
        #expect(b.isSuperset(of: [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]))
    }

    @Test func panelLevelIsStatusBarPlus8() {
        #expect(IslandPanel(contentRect: .zero).level.rawValue == NSWindow.Level.statusBar.rawValue + 8)
    }

    @Test func panelBecomesKeyOnlyWhenAllowed() {
        let p = IslandPanel(contentRect: .zero)
        #expect(!p.canBecomeKey)
        p.allowsKey = true
        #expect(p.canBecomeKey)
        #expect(!p.canBecomeMain)
    }

    @Test func hotZoneReceivesMouseWhileIslandPanelIgnoresIt() {
        let c = IslandWindowController(screen: .mbp14, content: AnyView(Color.clear))
        defer { c.close() }
        #expect(c.panel.ignoresMouseEvents && !c.hotZone.ignoresMouseEvents)
    }

    @Test func controllerPositionsPanelAndHotZoneFromGeometry() {
        let c = IslandWindowController(screen: .mbp14, content: AnyView(Color.clear))
        defer { c.close() }
        let notch = NotchGeometry.metrics(for: .mbp14)
        let zone = IslandMetrics.hotZone(around: notch.rect, screenTop: ScreenDescriptor.mbp14.frame.maxY)
        c.layout(screen: .mbp14, hotZoneRect: zone)
        #expect(c.panel.frame == IslandMetrics.panelFrame(notch: notch, screen: .mbp14) && c.hotZone.frame == zone)
    }

    /// Hover comes from the container's own tracking against the island region, including the panel's top boundary.
    @Test func containerReportsHoverAgainstTheIslandRegion() throws {
        let c = IslandWindowController(screen: .mbp14, content: AnyView(Color.clear))
        defer { c.close() }
        var reports: [Bool] = []
        c.container.hoverRegion = { [CGRect(x: 100, y: -4, width: 200, height: 40)] }
        c.container.onHoverChange = { reports.append($0) }
        let height = c.container.bounds.height
        for y in [height, height - 10, height - 100] {
            let event = try #require(
                NSEvent.mouseEvent(
                    with: .mouseMoved, location: NSPoint(x: 150, y: y), modifierFlags: [], timestamp: 0,
                    windowNumber: c.panel.windowNumber, context: nil, eventNumber: 0, clickCount: 0, pressure: 0))
            c.container.mouseMoved(with: event)
        }
        #expect(reports == [true, false])
    }

    @Test func scrollOverOpenIslandIsForwarded() throws {
        let c = IslandWindowController(screen: .mbp14, content: AnyView(Color.clear))
        defer { c.close() }
        let spy = ScrollSpy()
        c.scrollDelegate = spy
        let cg = try #require(
            CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: -30, wheel2: 0, wheel3: 0))
        let event = try #require(NSEvent(cgEvent: cg))
        c.container.scrollWheel(with: event)
        #expect(spy.calls == 1)
    }

    @Test func resigningKeyReportsClickOutside() {
        let c = IslandWindowController(screen: .mbp14, content: AnyView(Color.clear))
        defer { c.close() }
        var resigned = false
        c.onResignKey = { resigned = true }
        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: c.panel)
        #expect(resigned)
    }

    @Test func layoutFollowsNewScreenFrame() {
        let c = IslandWindowController(screen: .mbp14, content: AnyView(Color.clear))
        defer { c.close() }
        var moved = ScreenDescriptor.mbp14
        moved.frame.origin.x = -1512
        moved.visibleFrame.origin.x = -1512
        moved.auxiliaryTopLeft?.origin.x = -1512
        moved.auxiliaryTopRight?.origin.x = -662
        c.layout(screen: moved, hotZoneRect: .zero)
        #expect(c.panel.frame == IslandMetrics.panelFrame(notch: NotchGeometry.metrics(for: moved), screen: moved))
    }

    @Test func managerRemovesControllersForDisconnectedScreens() {
        let m = IslandWindowManager()
        #expect(m.sync(screens: [.mbp14, .external], mode: .allDisplays) { _ in AnyView(EmptyView()) }.count == 2)
        #expect(m.sync(screens: [.mbp14], mode: .allDisplays) { _ in AnyView(EmptyView()) }.keys.sorted() == [1])
        m.controller(for: 1)?.close()
    }
}

@MainActor private final class ScrollSpy: HotZoneDelegate {
    var calls = 0
    func hotZoneEntered() {}
    func hotZoneExited() {}
    func hotZoneMoved(to: NSPoint, at: TimeInterval) {}
    func hotZoneClicked(at: NSPoint, button: HotZoneButton) {}
    func hotZoneScrolled(deltaY: CGFloat, phase: NSEvent.Phase, momentumPhase: NSEvent.Phase, inverted: Bool) {
        calls += 1
    }
}
