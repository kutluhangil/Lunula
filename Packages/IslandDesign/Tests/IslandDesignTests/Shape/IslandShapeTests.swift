import SwiftUI
import Testing

@testable import IslandDesign

@Suite struct IslandShapeTests {
    let rect = CGRect(x: 0, y: 0, width: 300, height: 60)
    var path: Path { IslandShape(shoulderRadius: 12, cornerRadius: 26).path(in: rect) }
    @Test func pathBoundsEqualRect() {
        let b = path.boundingRect
        #expect(abs(b.minX) < 0.5 && abs(b.minY) < 0.5 && abs(b.width - 300) < 0.5 && abs(b.height - 60) < 0.5)
    }
    @Test func centerIsInside() { #expect(path.contains(CGPoint(x: 150, y: 30))) }
    @Test func shoulderFlaresOutwardAtTop() {
        #expect(path.contains(CGPoint(x: 6, y: 0.5)))  // inside the shoulder at the top edge
        #expect(!path.contains(CGPoint(x: 1, y: 12)))  // below the shoulder, left of the body: outside
    }
    @Test func bottomCornersAreRounded() {
        #expect(!path.contains(CGPoint(x: 13, y: 59)))
        #expect(path.contains(CGPoint(x: 20, y: 30)))
    }
    @Test func zeroShoulderDegeneratesToBodyOnly() {
        #expect(IslandShape(shoulderRadius: 0, cornerRadius: 10).path(in: rect).contains(CGPoint(x: 0.5, y: 0.5)))
    }
    @Test func tinyRectDoesNotOverflow() {
        let small = CGRect(x: 0, y: 0, width: 40, height: 20)
        let b = IslandShape.expanded.path(in: small).boundingRect
        #expect(b.width <= 40.5 && b.height <= 20.5)
    }
    @Test func radiiAnimateTogether() {
        var s = IslandShape.closed
        s.animatableData = AnimatablePair(12, 26)
        #expect(s.shoulderRadius == 12 && s.cornerRadius == 26)
    }
}
