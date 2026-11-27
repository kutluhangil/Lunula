import Foundation
import IslandCore
import IslandCoreTestSupport
import Testing

@testable import IslandServices

@Suite struct AudioSpectrumTests {
    @Test func computeBandsReturnsEightZerosForEmptyOrSilentBuffers() {
        let empty = AudioSpectrumMath.computeBands(samples: [])
        #expect(empty == Array(repeating: 0, count: 8))

        let tooShort = AudioSpectrumMath.computeBands(samples: Array(repeating: 0.5, count: 128))
        #expect(tooShort == Array(repeating: 0, count: 8))

        let silent = AudioSpectrumMath.computeBands(samples: Array(repeating: 0, count: 512))
        #expect(silent == Array(repeating: 0, count: 8))
    }

    @Test func computeBandsProducesBoundedNonZeroSpectrumFor440HzSineWave() {
        let sampleRate = 48_000.0
        let samples = (0..<512).map { index in
            Float(sin(2.0 * .pi * 440.0 * Double(index) / sampleRate))
        }

        let bands = AudioSpectrumMath.computeBands(samples: samples)
        #expect(bands.count == 8)
        #expect(bands.allSatisfy { (0.0...1.0).contains($0) })
        #expect((bands.max() ?? 0) > 0.2)
    }

    @Test func simulatedBandsRespectPlaybackStateAndBounds() {
        let paused = AudioSpectrumMath.simulatedBands(at: 12.5, isPlaying: false)
        #expect(paused == Array(repeating: 0, count: 8))

        let playingA = AudioSpectrumMath.simulatedBands(at: 12.5, isPlaying: true)
        let playingB = AudioSpectrumMath.simulatedBands(at: 12.8, isPlaying: true)
        #expect(playingA.count == 8)
        #expect(playingA.allSatisfy { (0.0...1.0).contains($0) && $0 > 0 })
        #expect(playingB.allSatisfy { (0.0...1.0).contains($0) && $0 > 0 })
        #expect(playingA != playingB)
    }

    @Test @MainActor func serviceFallsBackToSimulatedBandsAndStopsCleanly() {
        let clock = ManualTime()
        let service = AudioSpectrumService(time: clock)

        service.start(liveTapAllowed: false, isPlaying: true)
        #expect(service.isActive)
        #expect(!service.isUsingLiveTap)
        #expect(service.bands.count == 8)
        #expect((service.bands.max() ?? 0) > 0)

        let initial = service.bands
        clock.advance(by: 0.16)
        #expect(service.bands != initial)

        service.stop()
        #expect(!service.isActive)
        #expect(service.bands == Array(repeating: 0, count: 8))
    }
}
