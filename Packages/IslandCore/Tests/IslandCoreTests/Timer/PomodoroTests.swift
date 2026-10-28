import Foundation
import Testing

@testable import IslandCore

@Suite struct PomodoroTests {
    @Test func standardPlanIs25_5_15x4() {
        #expect(
            PomodoroPlan.standard
                == PomodoroPlan(focus: 1500, shortBreak: 300, longBreak: 900, focusSessionsBeforeLongBreak: 4))
    }
    @Test func focusLeadsToShortBreakAndBreakLeadsToFocus() {
        var p = PomodoroProgress()
        p.advance(plan: .standard)
        #expect(p.phase == .shortBreak)
        p.advance(plan: .standard)
        #expect(p.phase == .focus)
    }
    @Test func fourthFocusLeadsToLongBreak() {
        var p = PomodoroProgress()
        for _ in 0..<7 { p.advance(plan: .standard) }  // F→S→F→S→F→S→F→L
        #expect(p.phase == .longBreak && p.completedFocusSessions == 4 && p.duration(plan: .standard) == 900)
    }
}
