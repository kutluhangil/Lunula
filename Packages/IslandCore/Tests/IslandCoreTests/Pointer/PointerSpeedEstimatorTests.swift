import Foundation
import Testing

@testable import IslandCore

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite struct PointerSpeedEstimatorTests {
    @Test func speedIsDistanceOverTimeWithinWindow() {
        var e = PointerSpeedEstimator()
        e.add(.zero, at: 0)
        e.add(CGPoint(x: 30, y: 40), at: 0.05)
        #expect(abs(e.speed(at: 0.05) - 1000) < 0.001)
    }

    @Test func oldSamplesAreIgnored() {
        var e = PointerSpeedEstimator()
        e.add(.zero, at: 0)
        e.add(CGPoint(x: 500, y: 0), at: 0.01)
        e.add(CGPoint(x: 500, y: 0), at: 1.0)
        e.add(CGPoint(x: 501, y: 0), at: 1.02)
        #expect(e.speed(at: 1.02) < 100)
    }

    @Test func singleSampleIsZero() {
        var e = PointerSpeedEstimator()
        e.add(.zero, at: 0)
        #expect(e.speed(at: 0) == 0)
    }
}
