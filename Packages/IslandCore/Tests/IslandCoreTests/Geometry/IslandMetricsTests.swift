import Foundation
import IslandCoreTestSupport
import Testing

@testable import IslandCore

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

private let mbp14 = ScreenDescriptor.mbp14
private let external = ScreenDescriptor.external

@Suite struct IslandMetricsTests {
    let notch = NotchGeometry.metrics(for: mbp14)  // 188 x 32
    @Test func idleSizeEqualsNotch() {
        #expect(IslandMetrics.size(for: .idle, notch: notch) == CGSize(width: 188, height: 32))
    }
    @Test func inviteAdds8ptPerSide() {
        #expect(IslandMetrics.size(for: .invite, notch: notch) == CGSize(width: 204, height: 32))
    }
    @Test func compactWingClampedTo64() {
        #expect(IslandMetrics.size(for: .compact(wing: 80), notch: notch).width == CGFloat(188 + 128))
    }
    @Test func peekHasMinimumWidth340() {
        #expect(IslandMetrics.size(for: .peek, notch: notch) == CGSize(width: 340, height: 62))
    }
    @Test func expandedWidthAndBodyAreClamped() {
        #expect(
            IslandMetrics.size(for: .expanded(width: 500, bodyHeight: 100), notch: notch)
                == CGSize(width: 520, height: 32 + 128))
        #expect(
            IslandMetrics.size(for: .expanded(width: 700, bodyHeight: 300), notch: notch)
                == CGSize(width: 600, height: 32 + 176))
    }
    @Test func islandRectIsTopAlignedAndCenteredOnNotch() {
        let r = IslandMetrics.islandRect(size: CGSize(width: 340, height: 62), notch: notch)
        #expect(r.midX == notch.rect.midX && r.maxY == notch.rect.maxY)
    }
    @Test func bubblesSitRightOfPrimaryWith8ptGap() {
        let primary = CGRect(x: 600, y: 950, width: 300, height: 32)
        #expect(
            IslandMetrics.bubbleRect(index: 0, primary: primary, notch: notch)
                == CGRect(x: 908, y: 950, width: 32, height: 32))
        #expect(
            IslandMetrics.bubbleRect(index: 1, primary: primary, notch: notch)
                == CGRect(x: 948, y: 950, width: 32, height: 32))
    }
    @Test func hotZoneExpands10HorizontallyAnd6Down() {
        #expect(
            IslandMetrics.hotZone(around: CGRect(x: 100, y: 950, width: 188, height: 32), screenTop: 982)
                == CGRect(x: 90, y: 944, width: 208, height: 38))
    }
    /// A pill sits a few points below the top edge; the pointer resting on the edge must still reach it.
    @Test func hotZoneReachesTheScreenTopEdge() {
        #expect(
            IslandMetrics.hotZone(around: CGRect(x: 100, y: 1413, width: 180, height: 24), screenTop: 1440)
                == CGRect(x: 90, y: 1407, width: 200, height: 33))
    }
    @Test func panelFrameIs760x300TopCenteredAndInsideScreen() {
        let f = IslandMetrics.panelFrame(notch: notch, screen: mbp14)
        #expect(f.size == CGSize(width: 760, height: 300) && f.midX == notch.rect.midX && f.maxY == mbp14.frame.maxY)
        #expect(mbp14.frame.contains(f))
    }
}
