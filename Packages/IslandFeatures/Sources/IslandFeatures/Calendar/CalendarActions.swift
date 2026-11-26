import IslandCore
import SwiftUI

/// Join a meeting link; request calendar access (from the tile only). No-ops by default.
public struct CalendarActions {
    public var join: @MainActor (URL) -> Void = { _ in }
    public var requestAccess: @MainActor () -> Void = {}
    /// Read inside view bodies, so Observation re-renders the home tile when the next event changes.
    public var nextEvent: @MainActor () -> EventSnapshot? = { nil }
    /// All remaining timed events today, sorted chronologically.
    public var upcomingToday: @MainActor () -> [EventSnapshot] = { [] }
    /// All-day events for today.
    public var allDayToday: @MainActor () -> [EventSnapshot] = { [] }

    public init(
        join: @escaping @MainActor (URL) -> Void, requestAccess: @escaping @MainActor () -> Void,
        nextEvent: @escaping @MainActor () -> EventSnapshot?,
        upcomingToday: @escaping @MainActor () -> [EventSnapshot] = { [] },
        allDayToday: @escaping @MainActor () -> [EventSnapshot] = { [] }
    ) {
        self.join = join
        self.requestAccess = requestAccess
        self.nextEvent = nextEvent
        self.upcomingToday = upcomingToday
        self.allDayToday = allDayToday
    }

    init() {}
}

extension EnvironmentValues {
    @Entry public var calendarActions = CalendarActions()
}
