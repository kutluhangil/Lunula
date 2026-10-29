import AppKit
import EventKit
import IslandCore

/// One EKEventStore for the app's lifetime. Reads run in nonisolated async context, never on the main thread.
public final class EventKitReader: EventReading, @unchecked Sendable {  // EKEventStore is thread-safe for reads
    private let store = EKEventStore()

    public init() {}

    public func authorization() -> CalendarAuthorization {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined: .notDetermined
        case .fullAccess: .fullAccess
        case .writeOnly: .writeOnly
        case .restricted: .restricted
        default: .denied
        }
    }

    public func requestAccess() async -> CalendarAuthorization {
        _ = try? await store.requestFullAccessToEvents()
        let status = authorization()
        if status == .fullAccess { store.reset() }
        return status
    }

    public func events(from: Date, to: Date) async -> [CalendarEventRecord] {
        let predicate = store.predicateForEvents(withStart: from, end: to, calendars: nil)
        return store.events(matching: predicate).map { event in
            let color = event.calendar?.cgColor.flatMap { NSColor(cgColor: $0)?.usingColorSpace(.sRGB) }
            return CalendarEventRecord(
                id: event.eventIdentifier ?? event.calendarItemIdentifier, title: event.title ?? "",
                start: event.startDate, end: event.endDate, isAllDay: event.isAllDay,
                calendarColor: color.map {
                    RGBAColor(red: $0.redComponent, green: $0.greenComponent, blue: $0.blueComponent)
                },
                location: event.location, structuredLocationTitle: event.structuredLocation?.title, url: event.url,
                notes: event.notes,
                isDeclined: event.attendees?.first(where: \.isCurrentUser)?.participantStatus == .declined,
                isCanceled: event.status == .canceled)
        }
    }
}
