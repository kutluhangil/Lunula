import Foundation
import IslandCoreTestSupport
import Testing

@testable import IslandCore

@MainActor @Suite struct ManualTimeTests {
    @Test func advanceFiresDueActionsInDeadlineOrder() {
        let time = ManualTime()
        var log: [String] = []
        time.schedule(after: 2) { log.append("b") }
        time.schedule(after: 1) { log.append("a") }
        time.schedule(after: 5) { log.append("c") }
        time.advance(by: 3)
        #expect(log == ["a", "b"])
    }
    @Test func cancelledTokenDoesNotFire() {
        let time = ManualTime()
        var fired = false
        let token = time.schedule(after: 1) { fired = true }
        token.cancel()
        time.advance(by: 2)
        #expect(!fired && token.isCancelled)
    }
    @Test func actionScheduledDuringAdvanceFiresIfDue() {
        let time = ManualTime()
        var log: [String] = []
        time.schedule(after: 1) {
            log.append("a")
            time.schedule(after: 1) { log.append("b") }
        }
        time.advance(by: 3)
        #expect(log == ["a", "b"])
    }
}
