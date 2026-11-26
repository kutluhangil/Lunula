import Foundation
import IslandCore
import IslandCoreTestSupport
import SwiftUI
import Testing

@testable import IslandFeatures

@MainActor @Suite struct CalendarViewTests {
    let now = Date(timeIntervalSinceReferenceDate: 0)

    @Test func labelSwitchesAroundStart() {
        #expect(CalendarLabel.state(start: now.addingTimeInterval(300), now: now) == .countdown)
        #expect(CalendarLabel.state(start: now.addingTimeInterval(30), now: now) == .now)
        #expect(CalendarLabel.state(start: now.addingTimeInterval(-120), now: now) == .started)
    }

    @Test func joinButtonOnlyWithMeetingLink() {
        #expect(CalendarExpandedCard(event: .fixture(meetingLink: nil)).showsJoinButton == false)
        #expect(
            CalendarExpandedCard(
                event: .fixture(meetingLink: .init(service: .zoom, url: URL(string: "https://zoom.us/j/1")!))
            ).showsJoinButton)
    }

    @Test func viewsRender() {
        let primary = EventSnapshot.fixture(eventID: "1", title: "Standup")
        let later = EventSnapshot.fixture(eventID: "2", title: "Design Review", start: now.addingTimeInterval(3600))
        let actions = CalendarActions(
            join: { _ in }, requestAccess: {}, nextEvent: { primary }, upcomingToday: { [primary, later] },
            allDayToday: { [EventSnapshot.fixture(eventID: "all", title: "Release Day", isAllDay: true)] })
        #expect(
            ImageRenderer(
                content: CalendarExpandedCard(event: primary).frame(width: 492)
                    .environment(\.calendarActions, actions)
            ).cgImage != nil)
        #expect(
            ImageRenderer(
                content: NextEventTile(event: primary).frame(width: 160)
                    .environment(\.calendarActions, actions)
            ).cgImage != nil)
        #expect(
            ImageRenderer(
                content: CalendarAgendaPopover().environment(\.calendarActions, actions)
            ).cgImage != nil)
    }
}
