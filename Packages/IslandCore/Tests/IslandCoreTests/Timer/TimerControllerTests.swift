import Foundation
import IslandCoreTestSupport
import Testing

@testable import IslandCore

@MainActor @Suite struct TimerControllerTests {
    let time = ManualTime()

    func make(_ d: UserDefaults = UserDefaults(suiteName: UUID().uuidString)!) -> TimerController {
        TimerController(time: time, defaults: d)
    }

    @Test func startEmitsNormalTimerActivity() {
        let c = make()
        c.start(minutes: 25, label: nil)
        #expect(c.activities.first?.priority == .normal && c.activities.first?.id == "timer")
    }

    @Test func lastMinuteRaisesPriorityToHigh() {
        let c = make()
        c.start(minutes: 2, label: nil)
        time.advance(by: 61)
        #expect(c.activities.first?.priority == .high)
    }

    @Test func finishEmitsCriticalAlertOnce() {
        let c = make()
        var alerts: [TransientAlert] = []
        c.onAlert = { alerts.append($0) }
        c.start(minutes: 1, label: "Çay")
        time.advance(by: 120)
        #expect(alerts.count == 1 && alerts[0].kind == .timerFinished && alerts[0].priority == .critical)
        #expect(c.activities.isEmpty)
    }

    @Test func pomodoroAdvancesToBreakAndAutoStarts() {
        let c = make()
        c.startPomodoro()
        time.advance(by: 1500)
        #expect(
            c.pomodoro?.phase == .shortBreak && c.current?.phase == .shortBreak
                && c.current?.remaining(at: time.now) == 300)
    }

    @Test func restoresRunningTimerAfterRelaunch() {
        let d = UserDefaults(suiteName: UUID().uuidString)!
        make(d).start(minutes: 25, label: nil)
        time.advance(by: 60)
        #expect(make(d).current?.remaining(at: time.now) == 1440)
    }

    @Test func finishedWhileQuitAlertsOnceWithin10Minutes() {
        let d = UserDefaults(suiteName: UUID().uuidString)!
        make(d).start(minutes: 1, label: nil)
        time.advance(by: 300)
        var alerts = 0
        let c = make(d)
        c.onAlert = { _ in alerts += 1 }
        c.restore()
        #expect(alerts == 1 && c.current == nil)
    }

    @Test func cancelClearsActivityAndPersistence() {
        let d = UserDefaults(suiteName: UUID().uuidString)!
        let c = make(d)
        c.start(minutes: 5, label: nil)
        c.cancel()
        #expect(c.activities.isEmpty && make(d).current == nil)
    }

    @Test func focusCompletionReportsActualMinutesAndSkipsBreaks() {
        let c = make()
        var recorded: [Int] = []
        c.onFocusCompleted = { recorded.append($0) }
        c.start(minutes: 10, label: nil)
        time.advance(by: 601)
        c.startPomodoro()
        time.advance(by: 1501)  // 25 min focus finishes
        time.advance(by: 301)  // 5 min short break finishes (should not count as focus)
        #expect(recorded == [10, 25])
    }

    @Test func dynamicPomodoroPlanAppliesOnStart() {
        @MainActor final class PlanBox {
            var value: PomodoroPlan
            init(_ value: PomodoroPlan) { self.value = value }
        }
        let box = PlanBox(
            PomodoroPlan(focus: 1800, shortBreak: 600, longBreak: 1200, focusSessionsBeforeLongBreak: 2))
        let d = UserDefaults(suiteName: UUID().uuidString)!
        let c = TimerController(time: time, defaults: d, planProvider: { box.value })
        c.startPomodoro()
        #expect(c.current?.duration == 1800)
        box.value.focus = 2700
        c.startPomodoro()
        #expect(c.current?.duration == 2700)
    }
}
