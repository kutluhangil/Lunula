import Foundation
import IslandCoreTestSupport
import Testing

@testable import IslandCore

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite struct FullscreenHeuristicTests {
    let h: CGFloat = 982  // primary screen height (mbp14)
    func win(_ pid: Int32, layer: Int = 0, _ r: CGRect) -> WindowInfo {
        .init(ownerPID: pid, layer: layer, bounds: r, isOnscreen: true)
    }
    let menuBar = WindowInfo(
        ownerPID: 1, layer: 24, bounds: CGRect(x: 0, y: 0, width: 1512, height: 32), isOnscreen: true)
    @Test func windowCoveringWholeScreenIsFullscreen() {
        #expect(
            FullscreenHeuristic.isFullscreen(
                windows: [win(42, CGRect(x: 0, y: 0, width: 1512, height: 982))], frontmostPID: 42, screen: .mbp14,
                primaryScreenHeight: h))
    }
    @Test func windowBelowNotchCoveringRestIsFullscreen() {
        #expect(
            FullscreenHeuristic.isFullscreen(
                windows: [win(42, CGRect(x: 0, y: 32, width: 1512, height: 950))], frontmostPID: 42, screen: .mbp14,
                primaryScreenHeight: h))
    }
    @Test func maximizedWindowWithMenuBarVisibleIsNotFullscreen() {
        #expect(
            !FullscreenHeuristic.isFullscreen(
                windows: [menuBar, win(42, CGRect(x: 0, y: 32, width: 1512, height: 950))], frontmostPID: 42,
                screen: .mbp14, primaryScreenHeight: h))
    }
    @Test func otherAppsWindowDoesNotCount() {
        #expect(
            !FullscreenHeuristic.isFullscreen(
                windows: [win(7, CGRect(x: 0, y: 0, width: 1512, height: 982))], frontmostPID: 42, screen: .mbp14,
                primaryScreenHeight: h))
    }
    @Test func secondaryScreenUsesQuartzConversion() {
        // external: AppKit (1512, 0, 2560, 1440) -> Quartz y = 982 - 1440 = -458
        #expect(
            FullscreenHeuristic.isFullscreen(
                windows: [win(42, CGRect(x: 1512, y: -458, width: 2560, height: 1440))], frontmostPID: 42,
                screen: .external, primaryScreenHeight: h))
    }
}
