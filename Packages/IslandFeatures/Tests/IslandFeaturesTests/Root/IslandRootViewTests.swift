import Foundation
import IslandCore
import IslandCoreTestSupport
import SwiftUI
import Testing

@testable import IslandFeatures

@MainActor @Suite struct IslandRootViewTests {
    @Test(arguments: [
        IslandPhase.idle, .compact, .peek, .expanded(.home), .expanded(.shelf), .transient(.fixture()),
    ])
    func rootRendersEveryPhase(_ phase: IslandPhase) {
        #expect(
            ImageRenderer(content: IslandRootView.preview(phase: phase).frame(width: 760, height: 300)).cgImage != nil)
    }

    @Test func idleRendersOnlyBlackOrClearPixels() throws {
        let img = try #require(
            ImageRenderer(content: IslandRootView.preview(phase: .idle).frame(width: 760, height: 300)).cgImage)
        #expect(PixelProbe.allPixelsAreBlackOrTransparent(img, tolerance: 0.02))
    }
}
