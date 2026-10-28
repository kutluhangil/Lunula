import Foundation
import IslandCoreTestSupport
import Testing

@testable import IslandCore

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

private let mbp14 = ScreenDescriptor.mbp14
private let external = ScreenDescriptor.external

@Suite struct NotchGeometryTests {
    @Test func notchWidthIsFrameMinusAuxiliaryAreas() {
        let m = NotchGeometry.metrics(for: mbp14)
        #expect(m.hasHardwareNotch)
        #expect(m.rect == CGRect(x: 662, y: 950, width: 188, height: 32))
    }
    @Test func missingAuxiliaryAreasMeansPillMode() {
        #expect(!NotchGeometry.metrics(for: external).hasHardwareNotch)
    }
    @Test(arguments: [(24.0, 22.0), (33.0, 27.0), (37.0, 30.0)])
    func pillHeightIsMenuBarMinus6ClampedTo22through30(menuBar: Double, expected: Double) {
        var s = external
        s.menuBarHeight = menuBar
        #expect(NotchGeometry.metrics(for: s).rect.height == CGFloat(expected))
    }
    @Test func pillIsCenteredInMenuBarBand() {
        let r = NotchGeometry.metrics(for: external).rect  // menuBar 24, height 22
        #expect(r.midX == external.frame.midX)
        #expect(r.width == NotchGeometry.pillBaseWidth)
        #expect(r.maxY == external.frame.maxY - 1)  // (24 - 22) / 2
    }
}
