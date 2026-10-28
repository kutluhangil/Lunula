import Foundation
import IslandCoreTestSupport
import Testing

@testable import IslandCore

@Suite struct NowPlayingSnapshotTests {
    let t0 = Date(timeIntervalSinceReferenceDate: 0)
    @Test func positionInterpolatesWhilePlaying() {
        let s = NowPlayingSnapshot.fixture(duration: 200, position: 10, positionTimestamp: t0, isPlaying: true)
        #expect(s.position(at: t0.addingTimeInterval(5)) == 15)
    }
    @Test func positionFrozenWhenPaused() {
        let s = NowPlayingSnapshot.fixture(duration: 200, position: 10, positionTimestamp: t0, isPlaying: false)
        #expect(s.position(at: t0.addingTimeInterval(5)) == 10)
    }
    @Test func positionClampsToDuration() {
        let s = NowPlayingSnapshot.fixture(duration: 12, position: 10, positionTimestamp: t0, isPlaying: true)
        #expect(s.position(at: t0.addingTimeInterval(5)) == 12)
    }
}
