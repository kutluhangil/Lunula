import Foundation
import IslandCore

public let fixtureReferenceDate = Date(timeIntervalSinceReferenceDate: 800_000_000)

extension Activity {
    public static func fixture(
        id: ActivityID = "activity",
        priority: ActivityPriority = .normal,
        startedAt: Date = fixtureReferenceDate,
        updatedAt: Date = fixtureReferenceDate,
        expiresAt: Date? = nil,
        content: ActivityContent = .custom(
            CustomActivitySnapshot(title: "Activity", subtitle: nil, symbol: nil, progress: nil, endsAt: nil)),
        accent: RGBAColor? = nil
    ) -> Activity {
        Activity(
            id: id, priority: priority, startedAt: startedAt, updatedAt: updatedAt, expiresAt: expiresAt,
            content: content, accent: accent)
    }
}

extension NowPlayingSnapshot {
    public static func fixture(
        source: MediaSourceID = .music,
        trackID: String = "track-1",
        title: String = "Title",
        artist: String = "Artist",
        album: String? = "Album",
        artworkKey: String? = nil,
        duration: TimeInterval? = 200,
        position: TimeInterval = 0,
        positionTimestamp: Date = fixtureReferenceDate,
        isPlaying: Bool = true
    ) -> NowPlayingSnapshot {
        NowPlayingSnapshot(
            source: source, trackID: trackID, title: title, artist: artist, album: album, artworkKey: artworkKey,
            duration: duration, position: position, positionTimestamp: positionTimestamp, isPlaying: isPlaying)
    }
}

extension EventSnapshot {
    public static func fixture(
        eventID: String = "event-1",
        title: String = "Event",
        start: Date = fixtureReferenceDate,
        end: Date? = nil,
        isAllDay: Bool = false,
        calendarColor: RGBAColor? = nil,
        location: String? = nil,
        meetingLink: MeetingLink? = nil
    ) -> EventSnapshot {
        EventSnapshot(
            eventID: eventID, title: title, start: start, end: end ?? start.addingTimeInterval(1800),
            isAllDay: isAllDay, calendarColor: calendarColor, location: location, meetingLink: meetingLink)
    }
}

extension TransientAlert {
    public static func fixture(
        id: UUID = UUID(),
        kind: AlertKind = .custom,
        detail: AlertDetail = .text(title: "Alert", subtitle: nil, symbol: nil),
        tint: SignalTint = .neutral,
        duration: TimeInterval = 2.6,
        priority: ActivityPriority = .normal
    ) -> TransientAlert {
        TransientAlert(id: id, kind: kind, detail: detail, tint: tint, duration: duration, priority: priority)
    }
}

extension WeatherSnapshot {
    public static func fixture(
        temperatureC: Double = 20,
        highC: Double = 24,
        lowC: Double = 14,
        condition: WeatherCondition = .clear,
        isDaylight: Bool = true,
        sunrise: Date? = nil,
        sunset: Date? = nil,
        placeName: String? = "Istanbul",
        fetchedAt: Date = fixtureReferenceDate
    ) -> WeatherSnapshot {
        WeatherSnapshot(
            temperatureC: temperatureC, highC: highC, lowC: lowC, condition: condition, isDaylight: isDaylight,
            sunrise: sunrise, sunset: sunset, placeName: placeName, fetchedAt: fetchedAt)
    }
}
