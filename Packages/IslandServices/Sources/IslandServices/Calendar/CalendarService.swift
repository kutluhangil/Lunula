import EventKit
import Foundation
import IslandCore
import Observation

/// Next event and today's all-day events. Never asks for access by itself. Refreshes on store changes, at midnight
/// and at the next activity boundary (start − 10 min, start + 5 min) with a single timer.
@MainActor @Observable public final class CalendarService: ActivityProviding {
    static let lookahead: TimeInterval = 12 * 3600
    static let leadTime: TimeInterval = 600
    static let tailTime: TimeInterval = 300

    @ObservationIgnored private let reader: EventReading
    @ObservationIgnored private let time: IslandTime
    @ObservationIgnored private let center: NotificationCenter
    @ObservationIgnored private var observer: NSObjectProtocol?
    @ObservationIgnored private var boundary: ScheduledToken?
    @ObservationIgnored public var onActivitiesChange: (@MainActor () -> Void)?

    public private(set) var nextEvent: EventSnapshot?
    public private(set) var allDayToday: [EventSnapshot] = []
    public private(set) var authorization: CalendarAuthorization = .notDetermined

    public init(reader: EventReading, time: IslandTime, center: NotificationCenter = .default) {
        self.reader = reader
        self.time = time
        self.center = center
    }

    public var activities: [Activity] {
        guard let event = nextEvent else { return [] }
        let now = time.now
        guard now >= event.start.addingTimeInterval(-Self.leadTime), now < event.start.addingTimeInterval(Self.tailTime)
        else { return [] }
        let content = ActivityContent.calendar(event)
        return [
            Activity(
                id: ActivityID("calendar.\(event.eventID)"),
                priority: ActivityPriorityRules.priority(for: content, now: now),
                startedAt: event.start.addingTimeInterval(-Self.leadTime), updatedAt: now, expiresAt: nil,
                content: content, accent: event.calendarColor)
        ]
    }

    public func start() {
        authorization = reader.authorization()
        if observer == nil {
            observer = center.addObserver(forName: .EKEventStoreChanged, object: nil, queue: nil) { [weak self] _ in
                Task { @MainActor [weak self] in self?.refresh() }
            }
        }
        refresh()
    }

    public func stop() {
        if let observer { center.removeObserver(observer) }
        observer = nil
        boundary?.cancel()
    }

    public func requestAccess() async {
        authorization = await reader.requestAccess()
        refresh()
    }

    private func refresh() {
        authorization = reader.authorization()
        guard authorization == .fullAccess else {
            apply([], now: time.now)
            return
        }
        let now = time.now
        let reader = reader
        Task {
            let records = await reader.events(from: now, to: now.addingTimeInterval(Self.lookahead))
            apply(records, now: time.now)
        }
    }

    private func apply(_ records: [CalendarEventRecord], now: Date) {
        let usable = records.filter { !$0.isDeclined && !$0.isCanceled }
        allDayToday = usable.filter(\.isAllDay).sorted { $0.start < $1.start }.map(Self.snapshot)
        nextEvent = usable.filter { !$0.isAllDay && $0.start.addingTimeInterval(Self.tailTime) > now }
            .min { $0.start < $1.start }.map(Self.snapshot)
        scheduleBoundary(now: now)
        onActivitiesChange?()
    }

    private func scheduleBoundary(now: Date) {
        boundary?.cancel()
        let midnight = Calendar.current.startOfDay(for: now).addingTimeInterval(86_400)
        let edges = [
            nextEvent?.start.addingTimeInterval(-Self.leadTime), nextEvent?.start.addingTimeInterval(Self.tailTime),
        ]
        let next = (edges.compactMap { $0 } + [midnight]).filter { $0 > now }.min() ?? midnight
        boundary = time.schedule(after: next.timeIntervalSince(now)) { [weak self] in self?.refresh() }
    }

    private static func snapshot(_ r: CalendarEventRecord) -> EventSnapshot {
        EventSnapshot(
            eventID: r.id, title: r.title, start: r.start, end: r.end, isAllDay: r.isAllDay,
            calendarColor: r.calendarColor, location: r.location ?? r.structuredLocationTitle,
            meetingLink: MeetingLinkDetector.detect(in: [
                r.url?.absoluteString, r.location, r.structuredLocationTitle, r.notes,
            ]))
    }
}
