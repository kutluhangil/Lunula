import Foundation
import IslandCore
import IslandCoreTestSupport
import IslandDesign
import Testing

@testable import IslandFeatures

@Suite struct HaloDerivationTests {
    let now = Date(timeIntervalSinceReferenceDate: 0)

    @Test func idleIsOff() { #expect(HaloDerivation.state(phase: .idle, layout: .empty, now: now) == .off) }

    @Test func playingMusicBreathesInAccent() {
        let a = Activity.fixture(
            content: .nowPlaying(.fixture(isPlaying: true)), accent: RGBAColor(red: 0.2, green: 0.6, blue: 1))
        let h = HaloDerivation.state(
            phase: .compact, layout: .init(primary: a, detached: [], overflowCount: 0), now: now)
        #expect(h.mode == .ambient(breathing: true) && h.color == a.accent)
    }

    @Test func transientPulses() {
        #expect(HaloDerivation.state(phase: .transient(.fixture()), layout: .empty, now: now).mode == .pulse)
    }
}
