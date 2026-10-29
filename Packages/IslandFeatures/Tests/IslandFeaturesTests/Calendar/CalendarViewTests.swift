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
        #expect(ImageRenderer(content: CalendarExpandedCard(event: .fixture()).frame(width: 492)).cgImage != nil)
        #expect(ImageRenderer(content: NextEventTile(event: .fixture()).frame(width: 160)).cgImage != nil)
    }
}
