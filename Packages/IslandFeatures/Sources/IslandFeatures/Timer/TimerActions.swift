import SwiftUI

/// Timer commands injected by the App (Integrator); defaults are no-ops so views render in previews and tests.
public struct TimerActions {
    public var start: @MainActor (Double) -> Void = { _ in }
    public var startPomodoro: @MainActor () -> Void = {}
    public var pause: @MainActor () -> Void = {}
    public var resume: @MainActor () -> Void = {}
    public var cancel: @MainActor () -> Void = {}
    public var skip: @MainActor () -> Void = {}

    public init(
        start: @escaping @MainActor (Double) -> Void, startPomodoro: @escaping @MainActor () -> Void,
        pause: @escaping @MainActor () -> Void, resume: @escaping @MainActor () -> Void,
        cancel: @escaping @MainActor () -> Void, skip: @escaping @MainActor () -> Void
    ) {
        self.start = start
        self.startPomodoro = startPomodoro
        self.pause = pause
        self.resume = resume
        self.cancel = cancel
        self.skip = skip
    }

    init() {}
}

extension EnvironmentValues {
    @Entry public var timerActions = TimerActions()
}
