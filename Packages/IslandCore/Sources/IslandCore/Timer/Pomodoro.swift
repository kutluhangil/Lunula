import Foundation

public struct PomodoroPlan: Equatable, Sendable, Codable {
    public var focus: TimeInterval = 1500
    public var shortBreak: TimeInterval = 300
    public var longBreak: TimeInterval = 900
    public var focusSessionsBeforeLongBreak = 4

    public static let standard = PomodoroPlan()

    public init(
        focus: TimeInterval = 1500, shortBreak: TimeInterval = 300, longBreak: TimeInterval = 900,
        focusSessionsBeforeLongBreak: Int = 4
    ) {
        self.focus = focus
        self.shortBreak = shortBreak
        self.longBreak = longBreak
        self.focusSessionsBeforeLongBreak = focusSessionsBeforeLongBreak
    }
}

public struct PomodoroProgress: Equatable, Sendable, Codable {
    public var phase: TimerPhase = .focus
    public var completedFocusSessions = 0

    public init() {}

    public mutating func advance(plan: PomodoroPlan) {
        guard phase == .focus else {
            phase = .focus
            return
        }
        completedFocusSessions += 1
        phase = completedFocusSessions % max(1, plan.focusSessionsBeforeLongBreak) == 0 ? .longBreak : .shortBreak
    }

    public func duration(plan: PomodoroPlan) -> TimeInterval {
        switch phase {
        case .focus, .simple: plan.focus
        case .shortBreak: plan.shortBreak
        case .longBreak: plan.longBreak
        }
    }
}
