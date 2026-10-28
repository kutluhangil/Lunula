import Foundation
import IslandCoreTestSupport
import Testing

@testable import IslandCore

@Suite private struct ActivitySchedulerTests {
    let now = Date(timeIntervalSinceReferenceDate: 1_000)
    @Test func expiredActivitiesAreDropped() {
        let a = Activity.fixture(id: "a", expiresAt: now.addingTimeInterval(-1))
        #expect(ActivityScheduler.layout(for: [a], now: now) == .empty)
    }
    @Test func higherPriorityIsPrimary() {
        let low = Activity.fixture(id: "low", priority: .normal)
        let high = Activity.fixture(id: "high", priority: .critical)
        #expect(ActivityScheduler.layout(for: [low, high], now: now).primary?.id == "high")
    }
    @Test func tieBrokenByMostRecentUpdate() {
        let old = Activity.fixture(id: "old", priority: .normal, updatedAt: now.addingTimeInterval(-10))
        let new = Activity.fixture(id: "new", priority: .normal, updatedAt: now)
        #expect(ActivityScheduler.layout(for: [old, new], now: now).primary?.id == "new")
    }
    @Test func atMostTwoDetachedAndOverflowCounted() {
        let items = (0..<5).map {
            Activity.fixture(id: ActivityID("\($0)"), updatedAt: now.addingTimeInterval(Double($0)))
        }
        let l = ActivityScheduler.layout(for: items, now: now)
        #expect(l.primary?.id == "4" && l.detached.map(\.id) == ["3", "2"] && l.overflowCount == 2)
    }
}
