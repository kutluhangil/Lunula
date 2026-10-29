import Foundation
import Testing

@testable import IslandCore

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite struct IslandHitTestingTests {
    let island = CGRect(x: 0, y: 0, width: 300, height: 32)
    let bubble = CGRect(x: 308, y: 0, width: 32, height: 32)

    @Test func bubbleWinsOverIsland() {
        #expect(
            IslandHitTesting.target(at: CGPoint(x: 320, y: 10), island: island, bubbles: [("b", bubble)])
                == .bubble("b"))
    }

    @Test func islandHit() {
        #expect(IslandHitTesting.target(at: CGPoint(x: 10, y: 10), island: island, bubbles: []) == .island)
    }

    @Test func outsideReturnsNil() {
        #expect(IslandHitTesting.target(at: CGPoint(x: 500, y: 10), island: island, bubbles: []) == nil)
    }
}
