import SwiftUI
import Testing

@testable import IslandDesign

@Suite struct MetaballTests {
    @Test func blurIsZeroAtEndsAndPeaksAtMidpoint() {
        #expect(MetaballMath.blurRadius(progress: 0) == 0)
        #expect(MetaballMath.blurRadius(progress: 1) < 0.001)
        #expect(MetaballMath.blurRadius(progress: 0.5) == 6)
    }

    @Test func blurIsZeroOnSpringOvershoot() {
        #expect(MetaballMath.blurRadius(progress: 1.05) == 0)
        #expect(MetaballMath.blurRadius(progress: -0.05) == 0)
    }

    @Test func bubbleInterpolatesLinearly() {
        let r = MetaballMath.bubbleRect(
            progress: 0.5, from: CGRect(x: 0, y: 0, width: 10, height: 10),
            to: CGRect(x: 100, y: 0, width: 30, height: 30))
        #expect(r == CGRect(x: 50, y: 0, width: 20, height: 20))
    }

    @MainActor @Test func bridgeRendersOnlyBlackOrClearPixels() throws {
        let view = MetaballBridge(
            islandRect: CGRect(x: 10, y: 0, width: 120, height: 32),
            bubbleStart: CGRect(x: 100, y: 0, width: 32, height: 32),
            bubbleEnd: CGRect(x: 140, y: 0, width: 32, height: 32), progress: 0.5, islandCornerRadius: 10
        ).frame(width: 200, height: 40)
        let image = try #require(ImageRenderer(content: view).cgImage)
        #expect(PixelProbe.allPixelsAreBlackOrTransparent(image, tolerance: 0.02))
        #expect(PixelProbe.hasOpaqueContent(image))
        // (128, 1) lies outside both shapes: 12.0 pt from the island's top-right corner centre (120, 10), r = 10,
        // and 16.3 pt from the bubble centre (136, 16), r = 16. Only the gooey neck fills it.
        #expect(PixelProbe.alpha(image, x: 128, y: 1) > 127)
    }
}
