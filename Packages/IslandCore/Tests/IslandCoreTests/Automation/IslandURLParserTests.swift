import Foundation
import Testing

@testable import IslandCore

@Suite private struct IslandURLParserTests {
    func parse(_ s: String) -> Result<IslandURLCommand, IslandURLError> { IslandURLParser.parse(URL(string: s)!) }
    @Test func parsesShowActivityWithAllFields() {
        let r = parse(
            "lunula://activity/show?id=build&title=Derleme&subtitle=Lunula&symbol=hammer&accent=FF8000&progress=0.4&duration=600"
        )
        #expect(
            r
                == .success(
                    .showActivity(
                        .init(
                            id: "build", title: "Derleme", subtitle: "Lunula", symbol: "hammer",
                            accent: RGBAColor(hex: "FF8000"), progress: 0.4, duration: 600))))
    }
    @Test func percentDecodesTurkishCharacters() {
        guard
            case .success(.showActivity(let req)) = parse(
                "lunula://activity/show?id=m&title=Toplant%C4%B1%20ba%C5%9Fl%C4%B1yor")
        else {
            Issue.record()
            return
        }
        #expect(req.title == "Toplantı başlıyor")
    }
    @Test func rejectsMissingTitle() {
        #expect(parse("lunula://activity/show?id=a") == .failure(.missingParameter("title")))
    }
    @Test func clampsProgressAndTruncatesTitle() {
        guard
            case .success(.showActivity(let req)) = parse(
                "lunula://activity/show?id=a&title=\(String(repeating: "x", count: 100))&progress=1.7")
        else {
            Issue.record()
            return
        }
        #expect(req.progress == 1 && req.title.count == 80 && req.title.hasSuffix("…"))
    }
    @Test func rejectsDurationOver8Hours() {
        #expect(
            parse("lunula://activity/show?id=a&title=t&duration=40000") == .failure(.invalidParameter("duration")))
    }
    @Test func rejectsInvalidID() {
        #expect(parse("lunula://activity/show?id=a%20b&title=t") == .failure(.invalidParameter("id")))
    }
    @Test func parsesEndTimerAndToggle() {
        #expect(parse("lunula://activity/end?id=a") == .success(.endActivity(id: "a")))
        #expect(parse("lunula://timer/start?minutes=25") == .success(.startTimer(minutes: 25)))
        #expect(parse("lunula://island/toggle") == .success(.toggleIsland))
    }
    @Test func rejectsWrongSchemeAndUnknownCommand() {
        #expect(parse("other://activity/show?id=a&title=t") == .failure(.wrongScheme))
        #expect(parse("lunula://foo/bar") == .failure(.unknownCommand("foo/bar")))
    }
}
