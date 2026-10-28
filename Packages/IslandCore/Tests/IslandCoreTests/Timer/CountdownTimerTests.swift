import Foundation
import Testing

@testable import IslandCore

@Suite struct CountdownTimerTests {
    let t0 = Date(timeIntervalSinceReferenceDate: 0)
    func timer() -> CountdownTimer {
        CountdownTimer(id: "t", label: nil, phase: .simple, duration: 1500, startedAt: t0)
    }
    @Test func remainingUsesWallClockAcrossSleep() {
        let t = timer()
        #expect(t.remaining(at: t0.addingTimeInterval(1800)) == 0)
        #expect(t.isFinished(at: t0.addingTimeInterval(1800)))
        #expect(t.endDate() == t0.addingTimeInterval(1500))
    }
    @Test func pauseFreezesRemaining() {
        var t = timer()
        t.pause(at: t0.addingTimeInterval(100))
        #expect(t.remaining(at: t0.addingTimeInterval(900)) == 1400 && t.endDate() == nil)
    }
    @Test func resumeContinuesFromPausedValue() {
        var t = timer()
        t.pause(at: t0.addingTimeInterval(100))
        t.resume(at: t0.addingTimeInterval(400))
        #expect(t.remaining(at: t0.addingTimeInterval(500)) == 1300)
        #expect(t.endDate() == t0.addingTimeInterval(1800))
    }
}
