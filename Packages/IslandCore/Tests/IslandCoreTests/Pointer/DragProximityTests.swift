import Foundation
import Testing

@testable import IslandCore

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite struct DragProximityTests {
    let screen = CGRect(x: 0, y: 0, width: 1512, height: 982)

    @Test func pointWithin120ptOfTopApproaches() {
        #expect(DragProximity.isApproaching(point: CGPoint(x: 700, y: 900), screenFrame: screen))
    }

    @Test func pointBelowBandDoesNot() {
        #expect(!DragProximity.isApproaching(point: CGPoint(x: 700, y: 800), screenFrame: screen))
    }

    @Test func pointOnOtherScreenDoesNot() {
        #expect(!DragProximity.isApproaching(point: CGPoint(x: 2000, y: 950), screenFrame: screen))
    }
}
