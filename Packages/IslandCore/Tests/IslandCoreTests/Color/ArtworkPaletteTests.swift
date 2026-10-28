import Testing

@testable import IslandCore

@Suite struct ArtworkPaletteTests {
    @Test func accentIgnoresBlackAndGray() throws {
        let c = try #require(
            ArtworkPalette.accent(from: [
                .init(color: .black, weight: 0.7),
                .init(color: RGBAColor(red: 0.5, green: 0.5, blue: 0.5), weight: 0.2),
                .init(color: RGBAColor(red: 0.9, green: 0.1, blue: 0.1), weight: 0.1),
            ]))
        #expect(c.hsl.hue < 0.02 || c.hsl.hue > 0.98)
    }
    @Test func grayscaleArtworkHasNoAccent() {
        #expect(
            ArtworkPalette.accent(from: [.init(color: .black, weight: 0.5), .init(color: .white, weight: 0.5)]) == nil)
    }
}
