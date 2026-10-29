import Foundation
import IslandCore
import IslandCoreTestSupport
import Testing

@testable import IslandServices

final class FakeEventReader: EventReading, @unchecked Sendable {  // tests mutate records on the main actor only
    let status: CalendarAuthorization
    var records: [CalendarEventRecord]
    private(set) var requestCount = 0

    init(_ status: CalendarAuthorization, _ records: [CalendarEventRecord]) {
        self.status = status
        self.records = records
    }

    func authorization() -> CalendarAuthorization { status }
    func requestAccess() async -> CalendarAuthorization {
        requestCount += 1
        return status
    }
    func events(from: Date, to: Date) async -> [CalendarEventRecord] {
        records.filter { $0.end > from && $0.start < to }
    }
}

@MainActor @Suite struct CalendarServiceTests {
    let time = ManualTime()

    func rec(
        _ id: String, startsIn s: TimeInterval, allDay: Bool = false, declined: Bool = false, canceled: Bool = false,
        notes: String? = nil
    ) -> CalendarEventRecord {
        .init(
            id: id, title: id, start: time.now.addingTimeInterval(s), end: time.now.addingTimeInterval(s + 1800),
            isAllDay: allDay, calendarColor: nil, location: nil, structuredLocationTitle: nil, url: nil, notes: notes,
            isDeclined: declined, isCanceled: canceled)
    }

    @Test func nextEventSkipsAllDayDeclinedAndCanceled() async {
        let r = FakeEventReader(
            .fullAccess,
            [
                rec("allday", startsIn: 60, allDay: true), rec("no", startsIn: 120, declined: true),
                rec("x", startsIn: 180, canceled: true), rec("ok", startsIn: 240),
            ])
        let s = CalendarService(reader: r, time: time)
        s.start()
        await settle()
        #expect(s.nextEvent?.eventID == "ok" && s.allDayToday.map(\.eventID) == ["allday"])
    }

    @Test func activityExistsOnlyFromTenMinutesBeforeToFiveAfter() async {
        let s = CalendarService(reader: FakeEventReader(.fullAccess, [rec("m", startsIn: 900)]), time: time)
        s.start()
        await settle()
        #expect(s.activities.isEmpty)
        time.advance(by: 300)
        await settle()
        #expect(s.activities.count == 1)
        time.advance(by: 900)
        await settle()
        #expect(s.activities.isEmpty)
    }

    @Test func storeChangeTriggersRefresh() async {
        let center = NotificationCenter()
        let r = FakeEventReader(.fullAccess, [])
        let s = CalendarService(reader: r, time: time, center: center)
        s.start()
        await settle()
        r.records = [rec("new", startsIn: 600)]
        center.post(name: .EKEventStoreChanged, object: nil)
        await settle()
        #expect(s.nextEvent?.eventID == "new")
    }

    @Test func noAccessEmitsNothingAndNeverPrompts() async {
        let r = FakeEventReader(.notDetermined, [rec("m", startsIn: 60)])
        let s = CalendarService(reader: r, time: time)
        s.start()
        await settle()
        #expect(s.activities.isEmpty && s.nextEvent == nil && r.requestCount == 0)
    }

    @Test func meetingLinkAttached() async {
        let s = CalendarService(
            reader: FakeEventReader(
                .fullAccess, [rec("m", startsIn: 60, notes: "https://meet.google.com/abc-defg-hij")]),
            time: time)
        s.start()
        await settle()
        #expect(s.nextEvent?.meetingLink?.service == .googleMeet)
    }
}
