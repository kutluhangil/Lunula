import Foundation
import Testing

@testable import IslandServices

@Suite struct SpotifyScriptParserTests {
    let now = Date(timeIntervalSinceReferenceDate: 0)

    func row(
        id: String = "spotify:track:1", name: String = "Song", duration: Double = 215_000,
        art: String = "https://i.scdn.co/image/ab"
    ) -> ScriptValue {
        .list([
            .text("playing"), .text(name), .text("Artist"), .text("Album"), .number(duration), .number(12.5), .text(id),
            .text(art),
        ])
    }

    @Test func durationMillisecondsConvertedToSeconds() {
        #expect(SpotifyScriptParser.parse(row(), now: now)?.snapshot.duration == 215)
    }
    @Test func adReturnsNil() { #expect(SpotifyScriptParser.parse(row(id: "spotify:ad:xyz"), now: now) == nil) }
    @Test func emptyTitleReturnsNil() { #expect(SpotifyScriptParser.parse(row(name: ""), now: now) == nil) }
    @Test func rejectsNonHTTPSArtworkURL() {
        #expect(SpotifyScriptParser.parse(row(art: "http://x/y.jpg"), now: now)?.artworkURL == nil)
    }
}

@Suite struct SpotifySourceTests {
    @Test func appNotRunningProducesNilSnapshot() async {
        let fake = FakeExecutor(result: .success(.none))
        let s = SpotifySource(
            runner: ScriptRunner(executor: fake, isRunning: { _ in false }),
            cacheDirectory: FileManager.default.temporaryDirectory)
        #expect(await s.snapshot(now: Date()) == nil && fake.callCount == 0)
    }
}
