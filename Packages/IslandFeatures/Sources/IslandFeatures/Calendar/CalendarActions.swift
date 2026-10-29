import IslandCore
import SwiftUI

/// Join a meeting link; request calendar access (from the tile only). No-ops by default.
public struct CalendarActions {
    public var join: @MainActor (URL) -> Void = { _ in }
    public var requestAccess: @MainActor () -> Void = {}
    /// Read inside view bodies, so Observation re-renders the home tile when the next event changes.
    public var nextEvent: @MainActor () -> EventSnapshot? = { nil }

    public init(
        join: @escaping @MainActor (URL) -> Void, requestAccess: @escaping @MainActor () -> Void,
        nextEvent: @escaping @MainActor () -> EventSnapshot?
    ) {
        self.join = join
        self.requestAccess = requestAccess
        self.nextEvent = nextEvent
    }

    init() {}
}

extension EnvironmentValues {
    @Entry public var calendarActions = CalendarActions()
}
