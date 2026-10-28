import Foundation
import Testing

@testable import IslandCore

@Suite struct MeetingLinkDetectorTests {
    @Test func detectsZoomInURLField() {
        let l = MeetingLinkDetector.detect(in: ["https://us02web.zoom.us/j/123456789?pwd=abc", nil])
        #expect(l?.service == .zoom && l?.url.absoluteString == "https://us02web.zoom.us/j/123456789?pwd=abc")
    }
    @Test func detectsMeetInNotes() {
        #expect(
            MeetingLinkDetector.detect(in: [nil, "Join: https://meet.google.com/abc-defg-hij\nThanks"])?.url
                .absoluteString == "https://meet.google.com/abc-defg-hij")
    }
    @Test func detectsTeamsInsideHTMLAnchor() {
        let notes =
            #"<a href="https://teams.microsoft.com/l/meetup-join/19%3ameeting_X%40thread.v2/0?context=%7b%7d">Join</a>"#
        #expect(
            MeetingLinkDetector.detect(in: [notes])?.url.absoluteString
                == "https://teams.microsoft.com/l/meetup-join/19%3ameeting_X%40thread.v2/0?context=%7b%7d")
    }
    @Test func firstFieldWins() {
        #expect(
            MeetingLinkDetector.detect(in: ["https://zoom.us/j/1", "https://meet.google.com/abc-defg-hij"])?.service
                == .zoom)
    }
    @Test func ignoresNonMeetingLinks() {
        #expect(MeetingLinkDetector.detect(in: ["https://example.com/j/123"]) == nil)
    }
    @Test func stripsTrailingPunctuation() {
        #expect(
            MeetingLinkDetector.detect(in: ["(https://meet.google.com/abc-defg-hij)."])?.url.absoluteString
                == "https://meet.google.com/abc-defg-hij")
    }
    @Test func unwrapsOutlookSafeLinks() {
        let s = "https://eur01.safelinks.protection.outlook.com/?url=https%3A%2F%2Fzoom.us%2Fj%2F987&data=x"
        #expect(MeetingLinkDetector.detect(in: [s])?.url.absoluteString == "https://zoom.us/j/987")
    }
    @Test func detectsZoomAppSchemeFaceTimeAndWebex() {
        #expect(MeetingLinkDetector.detect(in: ["zoommtg://zoom.us/join?confno=123"])?.service == .zoom)
        #expect(MeetingLinkDetector.detect(in: ["https://facetime.apple.com/join#v=1&p=abc"])?.service == .facetime)
        #expect(MeetingLinkDetector.detect(in: ["https://acme.webex.com/meet/jane"])?.service == .webex)
    }
}
