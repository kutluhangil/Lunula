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
        #expect(c.panel.ignoresMouseEvents && !c.hotZone.ignoresMouseEvents)
    }

    @Test func controllerPositionsPanelAndHotZoneFromGeometry() {
        let c = IslandWindowController(screen: .mbp14, content: AnyView(Color.clear))
        let notch = NotchGeometry.metrics(for: .mbp14)
        let zone = IslandMetrics.hotZone(around: notch.rect)
        c.layout(screen: .mbp14, hotZoneRect: zone)
        #expect(c.panel.frame == IslandMetrics.panelFrame(notch: notch, screen: .mbp14) && c.hotZone.frame == zone)
    }

    @Test func managerRemovesControllersForDisconnectedScreens() {
        let m = IslandWindowManager()
        #expect(m.sync(screens: [.mbp14, .external], mode: .allDisplays) { _ in AnyView(EmptyView()) }.count == 2)
        #expect(m.sync(screens: [.mbp14], mode: .allDisplays) { _ in AnyView(EmptyView()) }.keys.sorted() == [1])
    }
}
