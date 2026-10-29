import Foundation
import Testing

@testable import IslandCore

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite struct SwipeDetectorTests {
    @Test func downwardSwipePast24ptIsDown() {
        var d = SwipeDetector()
        #expect(d.feed(deltaY: -10, phase: .began, isMomentum: false, inverted: false) == nil)
        #expect(d.feed(deltaY: -20, phase: .changed, isMomentum: false, inverted: false) == .down)
    }

    @Test func naturalScrollingInversionHandled() {
        var d = SwipeDetector()
        _ = d.feed(deltaY: 10, phase: .began, isMomentum: false, inverted: true)
        #expect(d.feed(deltaY: 20, phase: .changed, isMomentum: false, inverted: true) == .down)
    }

    @Test func momentumIsIgnored() {
        var d = SwipeDetector()
        #expect(d.feed(deltaY: -100, phase: .none, isMomentum: true, inverted: false) == nil)
    }

    @Test func smallMovementIsNotASwipe() {
        var d = SwipeDetector()
        #expect(d.feed(deltaY: -10, phase: .changed, isMomentum: false, inverted: false) == nil)
    }

    @Test func firesOncePerGesture() {
        var d = SwipeDetector()
        _ = d.feed(deltaY: -30, phase: .began, isMomentum: false, inverted: false)
        #expect(d.feed(deltaY: -30, phase: .changed, isMomentum: false, inverted: false) == nil)
    }
}
