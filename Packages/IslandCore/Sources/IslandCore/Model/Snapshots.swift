import Foundation

public enum MediaSourceID: String, Codable, Sendable { case music, spotify }

public struct NowPlayingSnapshot: Equatable, Sendable {
    public var source: MediaSourceID
    public var trackID: String
    public var title: String
    public var artist: String
    public var album: String?
    public var artworkKey: String?
    public var duration: TimeInterval?
    public var position: TimeInterval
    public var positionTimestamp: Date
    public var isPlaying: Bool

    public init(
        source: MediaSourceID, trackID: String, title: String, artist: String, album: String?, artworkKey: String?,
        duration: TimeInterval?, position: TimeInterval, positionTimestamp: Date, isPlaying: Bool
    ) {
        self.source = source
        self.trackID = trackID
        self.title = title
        self.artist = artist
        self.album = album
        self.artworkKey = artworkKey
        self.duration = duration
        self.position = position
        self.positionTimestamp = positionTimestamp
        self.isPlaying = isPlaying
    }

    /// Playback position at `now`: interpolated while playing, clamped to `0...duration`.
    public func position(at now: Date) -> TimeInterval {
        let raw = isPlaying ? position + now.timeIntervalSince(positionTimestamp) : position
        let lower = max(0, raw)
        return duration.map { min(lower, $0) } ?? lower
    }
}

public enum TimerPhase: String, Codable, Sendable { case simple, focus, shortBreak, longBreak }

/// `endsAt == nil` means the timer is paused.
public struct TimerSnapshot: Equatable, Sendable {
    public var timerID: ActivityID
    public var label: String?
    public var phase: TimerPhase
    public var duration: TimeInterval
    public var endsAt: Date?
    public var pausedRemaining: TimeInterval?
    public var cycle: Int?
    public var totalCycles: Int?

    public init(
        timerID: ActivityID, label: String?, phase: TimerPhase, duration: TimeInterval, endsAt: Date?,
        pausedRemaining: TimeInterval?, cycle: Int?, totalCycles: Int?
    ) {
        self.timerID = timerID
        self.label = label
        self.phase = phase
        self.duration = duration
        self.endsAt = endsAt
        self.pausedRemaining = pausedRemaining
        self.cycle = cycle
        self.totalCycles = totalCycles
    }
}

public enum MeetingService: String, Codable, Sendable { case zoom, googleMeet, teams, facetime, webex }

public struct MeetingLink: Equatable, Sendable {
    public var service: MeetingService
    public var url: URL

    public init(service: MeetingService, url: URL) {
        self.service = service
        self.url = url
    }
}

public struct EventSnapshot: Equatable, Sendable {
    public var eventID: String
    public var title: String
    public var start: Date
    public var end: Date
    public var isAllDay: Bool
    public var calendarColor: RGBAColor?
    public var location: String?
    public var meetingLink: MeetingLink?

    public init(
        eventID: String, title: String, start: Date, end: Date, isAllDay: Bool, calendarColor: RGBAColor?,
        location: String?, meetingLink: MeetingLink?
    ) {
        self.eventID = eventID
        self.title = title
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
        self.calendarColor = calendarColor
        self.location = location
        self.meetingLink = meetingLink
    }
}

public struct CustomActivitySnapshot: Equatable, Sendable {
    public var title: String
    public var subtitle: String?
    public var symbol: String?
    public var progress: Double?
    public var endsAt: Date?

    public init(title: String, subtitle: String?, symbol: String?, progress: Double?, endsAt: Date?) {
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.progress = progress
        self.endsAt = endsAt
    }
}

public struct BatterySnapshot: Equatable, Sendable {
    public var level: Int
    public var isCharging: Bool
    public var isPluggedIn: Bool
    public var isCharged: Bool
    public var isLowPowerMode: Bool
    public var hasBattery: Bool

    public init(
        level: Int, isCharging: Bool, isPluggedIn: Bool, isCharged: Bool, isLowPowerMode: Bool, hasBattery: Bool
    ) {
        self.level = level
        self.isCharging = isCharging
        self.isPluggedIn = isPluggedIn
        self.isCharged = isCharged
        self.isLowPowerMode = isLowPowerMode
        self.hasBattery = hasBattery
    }
}

public struct PrivacySnapshot: Equatable, Sendable {
    public var cameraInUse: Bool
    public var microphoneInUse: Bool

    public init(cameraInUse: Bool, microphoneInUse: Bool) {
        self.cameraInUse = cameraInUse
        self.microphoneInUse = microphoneInUse
    }

    public static let none = PrivacySnapshot(cameraInUse: false, microphoneInUse: false)
}

public enum WeatherCondition: String, Codable, CaseIterable, Sendable {
    case clear, partlyCloudy, cloudy, fog, drizzle, rain, snow, thunderstorm
}

public struct WeatherSnapshot: Codable, Equatable, Sendable {
    public var temperatureC: Double
    public var highC: Double
    public var lowC: Double
    public var condition: WeatherCondition
    public var isDaylight: Bool
    public var sunrise: Date?
    public var sunset: Date?
    public var placeName: String?
    public var fetchedAt: Date

    public init(
        temperatureC: Double, highC: Double, lowC: Double, condition: WeatherCondition, isDaylight: Bool,
        sunrise: Date?, sunset: Date?, placeName: String?, fetchedAt: Date
    ) {
        self.temperatureC = temperatureC
        self.highC = highC
        self.lowC = lowC
        self.condition = condition
        self.isDaylight = isDaylight
        self.sunrise = sunrise
        self.sunset = sunset
        self.placeName = placeName
        self.fetchedAt = fetchedAt
    }
}
