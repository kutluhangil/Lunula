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
        #expect(expanded.contains { $0.contains(CGPoint(x: 380, y: 0)) && $0.width == 520 })
        state.phase = .idle
        let idle = IslandRootView.hoverRegion(state: state, notch: notch)
        #expect(idle.contains { $0.contains(CGPoint(x: 380, y: 0)) })
        #expect(!idle.contains { $0.contains(CGPoint(x: 380, y: 120)) })
    }

    @Test func quickToolsPartitionPreventsNotchOverflow() {
        let slots = ExpandedView.maxInlineToolSlots(notchWidth: 188, hasLeadingSymbol: true)
        #expect(slots == 5)
        let widerSlots = ExpandedView.maxInlineToolSlots(
            notchWidth: 188, hasLeadingSymbol: true, expandedWidth: 600)
        #expect(widerSlots > slots)
        let part = ExpandedView.partitionQuickTools(["awake", "mic", "out", "drop", "notes", "clip"], maxSlots: slots)
        #expect(part.inline == ["awake", "mic", "out", "drop"])
        #expect(part.overflow == ["notes", "clip"])
        let fits = ExpandedView.partitionQuickTools(["awake", "mic", "out"], maxSlots: slots)
        #expect(fits.inline == ["awake", "mic", "out"] && fits.overflow.isEmpty)
    }

    @Test func hoverRegionRespectsCustomExpandedWidth() {
        var state = IslandState()
        state.phase = .expanded(.home)
        let wide = IslandRootView.hoverRegion(state: state, notch: IslandRootView.previewNotch, expandedWidth: 600)
        #expect(wide.contains { $0.width == 600 })
    }
}
