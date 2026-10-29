import Foundation
import IslandCore
import Testing

@testable import IslandServices

@Suite struct ArtworkColorTests {
    @Test func solidRedImageGivesRedAccent() throws {
        let c = try #require(
            ArtworkPalette.accent(
                from: ArtworkColorExtractor.weightedColors(
                    from: ImageFixtures.png(color: .init(red: 0.85, green: 0.1, blue: 0.1)))))
        #expect(c.hsl.hue < 0.03 || c.hsl.hue > 0.97)
    }

    @Test func blackImageGivesNoAccent() {
        #expect(
            ArtworkPalette.accent(from: ArtworkColorExtractor.weightedColors(from: ImageFixtures.png(color: .black)))
                == nil)
    }

    @Test func cachedAccentIsNotRecomputed() async {
        let store = ArtworkAccentStore()
        let loads = LoadCounter()
        let png = ImageFixtures.png(color: .init(red: 0.1, green: 0.5, blue: 0.9))
        _ = await store.accent(for: "k") {
            loads.increment()
            return png
        }
        _ = await store.accent(for: "k") {
            loads.increment()
            return png
        }
        #expect(loads.count == 1)
    }
}
