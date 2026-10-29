import Foundation

public enum HomeCard: Hashable, Sendable {
    case permission(MediaSourceID)
    case nowPlaying, meeting, timer, weather, nextEvent, timerQuickStart, calendarAccess
}

public struct HomeInputs: Equatable, Sendable {
    public var pendingPermission: MediaSourceID?
    public var hasNowPlaying: Bool
    public var hasImminentMeeting: Bool
    public var hasRunningTimer: Bool
    public var hasWeather: Bool
    public var hasUpcomingEvent: Bool
    public var calendarAccessUndetermined: Bool

    public init(
        pendingPermission: MediaSourceID?, hasNowPlaying: Bool, hasImminentMeeting: Bool, hasRunningTimer: Bool,
        hasWeather: Bool, hasUpcomingEvent: Bool, calendarAccessUndetermined: Bool
    ) {
        self.pendingPermission = pendingPermission
        self.hasNowPlaying = hasNowPlaying
        self.hasImminentMeeting = hasImminentMeeting
        self.hasRunningTimer = hasRunningTimer
        self.hasWeather = hasWeather
        self.hasUpcomingEvent = hasUpcomingEvent
        self.calendarAccessUndetermined = calendarAccessUndetermined
    }
}

/// Expanded home layout (spec §6.7): one hero card plus at most two tiles.
public enum HomeComposer {
    public static func compose(_ i: HomeInputs) -> (hero: HomeCard?, tiles: [HomeCard]) {
        let hero: HomeCard? =
            if let source = i.pendingPermission { .permission(source) } else if i.hasNowPlaying {
                .nowPlaying
            } else if i.hasImminentMeeting { .meeting } else if i.hasRunningTimer { .timer } else if i.hasWeather {
                .weather
            } else { nil }

        var tiles: [HomeCard] = []
        if i.hasWeather { tiles.append(.weather) }
        if i.hasUpcomingEvent {
            tiles.append(.nextEvent)
        } else if i.calendarAccessUndetermined {
            tiles.append(.calendarAccess)
        }
        if !i.hasRunningTimer { tiles.append(.timerQuickStart) }
        return (hero, Array(tiles.filter { $0 != hero }.prefix(2)))
    }
}
