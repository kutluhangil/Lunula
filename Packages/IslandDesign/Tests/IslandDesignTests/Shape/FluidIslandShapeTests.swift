import IslandCore
import SwiftUI
import Testing

@testable import IslandDesign

@Suite struct FluidIslandShapeTests {
    private let rect = CGRect(x: 0, y: 0, width: 300, height: 60)

    @Test func zeroTensionMatchesIslandShapeBoundsAndContainment() {
        let base = IslandShape.expanded
        let basePath = base.path(in: rect)
        let fluidPath = FluidIslandShape(base: base, tension: .zero).path(in: rect)

        #expect(fluidPath.boundingRect == basePath.boundingRect)

        let probes = [
            CGPoint(x: 150, y: 30),
            CGPoint(x: 6, y: 0.5),
            CGPoint(x: 1, y: 12),
            CGPoint(x: 13, y: 59),
            CGPoint(x: 20, y: 30),
        ]
        for point in probes {
            #expect(fluidPath.contains(point) == basePath.contains(point))
        }

        let pillBase = IslandShape.pill
        #expect(
            FluidIslandShape(base: pillBase, tension: .zero).path(in: rect).boundingRect
                == pillBase.path(in: rect).boundingRect
        )
    }

    @Test func positivePullYExtendsBottomWhileKeepingNotchTopFlush() {
        let tension = DropletTension(pullX: 2.5, pullY: 4.0, focusX: 0.65, intensity: 1.0)
        let shape = FluidIslandShape(base: .expanded, tension: tension)
        let deformed = shape.path(in: rect)
        let bounds = deformed.boundingRect

        #expect(abs(bounds.minY - 0) < 0.001)
        #expect(bounds.maxY > rect.maxY)
        #expect(abs(bounds.maxY - (rect.maxY + 4.0)) < 0.2)
        #expect(deformed.contains(CGPoint(x: 150, y: 30)))
        #expect(deformed.contains(CGPoint(x: 300 * 0.65, y: 63.0)))
    }

    @Test func expressivePullProducesValidPathWithTopEdgePinnedAtMinY() {
        let offsetRect = CGRect(x: 24, y: 12, width: 300, height: 60)
        let tension = DropletTension(pullX: 7.5, pullY: 6.0, focusX: 0.78, intensity: 1.0)
        let shape = FluidIslandShape(base: .expanded, tension: tension)
        let deformed = shape.path(in: offsetRect)
        let bounds = deformed.boundingRect

        #expect(!deformed.isEmpty)
        #expect(abs(bounds.minY - offsetRect.minY) < 0.001)
        #expect(abs(bounds.maxY - (offsetRect.maxY + 6.0)) < 0.25)
        #expect(deformed.contains(CGPoint(x: offsetRect.midX, y: offsetRect.midY)))
    }

    @Test func pillModeFlexesTowardTension() {
        let tension = DropletTension(pullX: -3.0, pullY: 3.5, focusX: 0.4, intensity: 1.0)
        let deformed = FluidIslandShape(base: .pill, tension: tension).path(in: rect)
        let bounds = deformed.boundingRect

        #expect(bounds.maxY > rect.maxY)
        #expect(deformed.contains(CGPoint(x: 150, y: 30)))
    }

    @Test func animatableDataRoundTripsAllFiveValues() {
        var shape = FluidIslandShape(base: .closed)
        shape.animatableData = AnimatablePair(
            AnimatablePair(12, 26),
            AnimatablePair(-3.5, AnimatablePair(4.2, 0.72))
        )

        #expect(shape.shoulderRadius == 12)
        #expect(shape.cornerRadius == 26)
        #expect(shape.pullX == -3.5)
        #expect(shape.pullY == 4.2)
        #expect(shape.focusX == 0.72)

        let data = shape.animatableData
        #expect(data.first.first == 12)
        #expect(data.first.second == 26)
        #expect(data.second.first == -3.5)
        #expect(data.second.second.first == 4.2)
        #expect(data.second.second.second == 0.72)
    }
}
