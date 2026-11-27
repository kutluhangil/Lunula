import Foundation
import IslandCore
import Testing

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite struct DropletPhysicsTests {
    private let island = CGRect(x: 200, y: 0, width: 200, height: 36)

    @Test func nilPointerAndDegenerateRectsReturnZero() {
        #expect(DropletPhysics.compute(pointer: nil, islandRect: island) == .zero)
        #expect(
            DropletPhysics.compute(
                pointer: CGPoint(x: 300, y: 18),
                islandRect: CGRect(x: 200, y: 0, width: 0, height: 36)
            ) == .zero
        )
        #expect(
            DropletPhysics.compute(
                pointer: CGPoint(x: 300, y: 18),
                islandRect: CGRect(x: 200, y: 0, width: 200, height: 0)
            ) == .zero
        )
    }

    @Test func farAwayPointerReturnsZeroAndHaloFallsOffSmoothly() {
        #expect(DropletPhysics.compute(pointer: CGPoint(x: 100, y: 18), islandRect: island) == .zero)
        #expect(DropletPhysics.compute(pointer: CGPoint(x: 450, y: 18), islandRect: island) == .zero)
        #expect(DropletPhysics.compute(pointer: CGPoint(x: 300, y: 80), islandRect: island) == .zero)
        #expect(DropletPhysics.compute(pointer: CGPoint(x: 300, y: 36 + 28), islandRect: island) == .zero)

        let haloNear = DropletPhysics.compute(pointer: CGPoint(x: 300, y: 36 + 10), islandRect: island)
        let haloFar = DropletPhysics.compute(pointer: CGPoint(x: 300, y: 36 + 22), islandRect: island)
        #expect(haloNear.intensity > haloFar.intensity)
        #expect(haloFar.intensity > 0 && haloNear.intensity < 1)
    }

    @Test func pointerInsideProducesBoundedPullAndAccurateFocus() {
        let left = DropletPhysics.compute(pointer: CGPoint(x: 220, y: 20), islandRect: island)
        #expect(left.intensity == 1.0)
        #expect(left.pullX < 0 && left.pullX >= -6.0)
        #expect(left.pullY > 0 && left.pullY <= 5.0)
        #expect(abs(left.focusX - 0.10) < 0.001)

        let right = DropletPhysics.compute(pointer: CGPoint(x: 380, y: 20), islandRect: island)
        #expect(right.intensity == 1.0)
        #expect(right.pullX > 0 && right.pullX <= 6.0)
        #expect(right.pullY > 0 && right.pullY <= 5.0)
        #expect(abs(right.focusX - 0.90) < 0.001)

        let bottom = DropletPhysics.compute(pointer: CGPoint(x: 300, y: 35), islandRect: island)
        #expect(bottom.intensity == 1.0)
        #expect(abs(bottom.pullX) < 0.001)
        #expect(bottom.pullY > 0 && bottom.pullY <= 5.0)
        #expect(abs(bottom.focusX - 0.5) < 0.001)

        let extremeLeft = DropletPhysics.compute(pointer: CGPoint(x: 200, y: 10), islandRect: island)
        let extremeRight = DropletPhysics.compute(pointer: CGPoint(x: 400, y: 10), islandRect: island)
        #expect(extremeLeft.focusX == 0.08)
        #expect(extremeRight.focusX == 0.92)
    }

    @Test func velocityBiasesPullWithoutExceedingBounds() {
        let center = CGPoint(x: 300, y: 18)
        let still = DropletPhysics.compute(pointer: center, islandRect: island, velocity: .zero)
        let glidingRightDown = DropletPhysics.compute(
            pointer: center,
            islandRect: island,
            velocity: CGSize(width: 400, height: 350)
        )
        #expect(glidingRightDown.pullX > still.pullX)
        #expect(glidingRightDown.pullY > still.pullY)

        let extremePositive = DropletPhysics.compute(
            pointer: CGPoint(x: 395, y: 35),
            islandRect: island,
            velocity: CGSize(width: 50_000, height: 50_000)
        )
        #expect(extremePositive.pullX == 6.0)
        #expect(extremePositive.pullY == 5.0)

        let extremeNegative = DropletPhysics.compute(
            pointer: CGPoint(x: 205, y: 1),
            islandRect: island,
            velocity: CGSize(width: -50_000, height: -50_000)
        )
        #expect(extremeNegative.pullX == -6.0)
        #expect(extremeNegative.pullY >= 0.0 && extremeNegative.pullY <= 5.0)
    }

    @Test func sensitivityScalesPullMagnitudeMonotonically() {
        let probe = CGPoint(x: 365, y: 26)
        let vel = CGSize(width: 120, height: 80)

        let subtle = DropletPhysics.compute(
            pointer: probe,
            islandRect: island,
            velocity: vel,
            sensitivity: .subtle
        )
        let balanced = DropletPhysics.compute(
            pointer: probe,
            islandRect: island,
            velocity: vel,
            sensitivity: .balanced
        )
        let expressive = DropletPhysics.compute(
            pointer: probe,
            islandRect: island,
            velocity: vel,
            sensitivity: .expressive
        )

        #expect(abs(subtle.pullX) < abs(balanced.pullX))
        #expect(abs(balanced.pullX) < abs(expressive.pullX))
        #expect(subtle.pullY < balanced.pullY)
        #expect(balanced.pullY < expressive.pullY)

        let maxExpressive = DropletPhysics.compute(
            pointer: CGPoint(x: 398, y: 35),
            islandRect: island,
            velocity: CGSize(width: 50_000, height: 50_000),
            sensitivity: .expressive
        )
        #expect(maxExpressive.pullX == DropletPhysics.maxPullX)
        #expect(maxExpressive.pullY == DropletPhysics.maxPullY)
    }

    @Test func meniscusSnapStretchBoostsDownwardBottomExitAndNeverGoesNegative() {
        let exitPoint = CGPoint(x: 300, y: island.maxY + 8)
        let belowThreshold = DropletPhysics.compute(
            pointer: exitPoint,
            islandRect: island,
            velocity: CGSize(width: 0, height: 29),
            sensitivity: .expressive
        )
        let snappingExit = DropletPhysics.compute(
            pointer: exitPoint,
            islandRect: island,
            velocity: CGSize(width: 0, height: 35),
            sensitivity: .expressive
        )
        #expect(snappingExit.pullY > belowThreshold.pullY * 1.20)

        for sensitivity in DropletSensitivity.allCases {
            let upward = DropletPhysics.compute(
                pointer: CGPoint(x: 300, y: 2),
                islandRect: island,
                velocity: CGSize(width: 0, height: -50_000),
                sensitivity: sensitivity
            )
            #expect(upward.pullY >= 0.0)
        }
    }
}
