import Foundation
import Testing

@testable import IslandCore

@Suite private struct RateLimiterTests {
    @Test func moreThan10In10SecondsAreDropped() {
        var l = RateLimiter()
        let t0 = Date(timeIntervalSinceReferenceDate: 0)
        let allowed = (0..<12).filter { l.allow(at: t0.addingTimeInterval(Double($0) * 0.1)) }.count
        #expect(allowed == 10 && l.allow(at: t0.addingTimeInterval(10.5)))
    }
}
