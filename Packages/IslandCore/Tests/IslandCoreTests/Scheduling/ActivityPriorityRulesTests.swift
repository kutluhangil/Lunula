import Foundation
import IslandCoreTestSupport
import Testing

@testable import IslandCore

@Suite private struct ActivityPriorityRulesTests {
    let now = Date(timeIntervalSinceReferenceDate: 1_000)
    func meeting(startsIn s: TimeInterval) -> ActivityContent { .calendar(.fixture(start: now.addingTimeInterval(s))) }
    func timer(endsIn s: TimeInterval?) -> ActivityContent {
        .timer(
            .init(
                timerID: "t", label: nil, phase: .simple, duration: 1500, endsAt: s.map { now.addingTimeInterval($0) },
                pausedRemaining: s == nil ? 100 : nil, cycle: nil, totalCycles: nil))
    }
    @Test func meetingWithin10MinIsHighAndWithin1MinIsCritical() {
        #expect(ActivityPriorityRules.priority(for: meeting(startsIn: 300), now: now) == .high)
        #expect(ActivityPriorityRules.priority(for: meeting(startsIn: 30), now: now) == .critical)
    }
    @Test func timerPriorities() {
        #expect(ActivityPriorityRules.priority(for: timer(endsIn: 600), now: now) == .normal)
        #expect(ActivityPriorityRules.priority(for: timer(endsIn: 45), now: now) == .high)
        #expect(ActivityPriorityRules.priority(for: timer(endsIn: 0), now: now) == .critical)
        #expect(ActivityPriorityRules.priority(for: timer(endsIn: nil), now: now) == .ambient)
    }
    @Test func pausedMusicIsAmbient() {
        #expect(ActivityPriorityRules.priority(for: .nowPlaying(.fixture(isPlaying: false)), now: now) == .ambient)
    }
    @Test func nextChangeForMeetingIsOneMinuteBeforeStart() {
        #expect(ActivityPriorityRules.nextChange(for: meeting(startsIn: 300), now: now) == now.addingTimeInterval(240))
    }
    @Test func nextChangeForTimerIsLastMinuteThenEnd() {
        #expect(ActivityPriorityRules.nextChange(for: timer(endsIn: 600), now: now) == now.addingTimeInterval(540))
        #expect(ActivityPriorityRules.nextChange(for: timer(endsIn: 30), now: now) == now.addingTimeInterval(30))
    }
}
