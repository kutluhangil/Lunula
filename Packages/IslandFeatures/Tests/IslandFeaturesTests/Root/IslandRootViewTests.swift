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

    /// Panel-local, top-left origin; the top row (y = 0, where a pointer rests on the screen edge) counts as inside.
    @Test func hoverRegionFollowsTheVisibleIsland() {
        var state = IslandState()
        let notch = IslandRootView.previewNotch
        state.phase = .expanded(.home)
        let expanded = IslandRootView.hoverRegion(state: state, notch: notch)
        #expect(expanded.contains { $0.contains(CGPoint(x: 380, y: 0)) && $0.width == 560 })
        state.phase = .idle
        let idle = IslandRootView.hoverRegion(state: state, notch: notch)
        #expect(idle.contains { $0.contains(CGPoint(x: 380, y: 0)) })
        #expect(!idle.contains { $0.contains(CGPoint(x: 380, y: 120)) })
    }
}
