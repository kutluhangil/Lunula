import Foundation
import Testing

@testable import IslandServices

@Suite struct MusicScriptParserTests {
    let now = Date(timeIntervalSinceReferenceDate: 0)
    func list(_ items: ScriptValue...) -> ScriptValue { .list(items) }

    @Test func parsesPlayingTrack() throws {
        let s = try #require(
            MusicScriptParser.parse(
                list(
                    .text("playing"), .text("Bir Derdim Var"), .text("mor ve ötesi"), .text("Dünya Yalan Söylüyor"),
                    .number(245.3), .number(61.0), .text("ABC123")), now: now))
        #expect(
            s.title == "Bir Derdim Var" && s.artist == "mor ve ötesi" && s.duration == 245.3 && s.position == 61
                && s.isPlaying && s.trackID == "ABC123")
    }

    @Test func pausedTrackIsNotPlaying() {
        #expect(
            MusicScriptParser.parse(
                list(.text("paused"), .text("a"), .text("b"), .text("c"), .number(10), .number(1), .text("id")),
                now: now)?.isPlaying == false)
    }

    @Test func stoppedReturnsNil() { #expect(MusicScriptParser.parse(list(.text("stopped")), now: now) == nil) }

    @Test func emptyTitleReturnsNil() {
        #expect(
            MusicScriptParser.parse(
                list(.text("playing"), .text(""), .text(""), .text(""), .number(0), .number(0), .text("id")), now: now)
                == nil)
    }

    @Test func malformedValueReturnsNil() { #expect(MusicScriptParser.parse(.text("garbage"), now: now) == nil) }
}

@Suite struct MusicSourceTests {
    @Test func appNotRunningProducesNilSnapshot() async {
        let fake = FakeExecutor(result: .success(.none))
        let source = MusicSource(runner: ScriptRunner(executor: fake, isRunning: { _ in false }))
        #expect(await source.snapshot(now: Date()) == nil && fake.callCount == 0)
    }

    @Test func seekSendsSetPlayerPosition() async {
        let fake = FakeExecutor(result: .success(.none))
        await MusicSource(runner: ScriptRunner(executor: fake, isRunning: { _ in true })).perform(.seek(42))
        #expect(fake.lastSource?.contains("set player position to 42") == true)
    }
}
