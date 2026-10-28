import Testing

@testable import IslandCore

@Suite struct ColorMathTests {
    @Test func contrastOfWhiteOnBlackIs21() { #expect(abs(RGBAColor.white.contrastRatio(with: .black) - 21) < 0.01) }
    @Test func adjustedAccentMeetsThreeToOneOnBlackAndKeepsHue() {
        let navy = RGBAColor(red: 0.06, green: 0.06, blue: 0.25)
        let adjusted = navy.adjustedForBlackBackground()
        #expect(adjusted.contrastRatio(with: .black) >= 3.0)
        #expect(abs(adjusted.hsl.hue - navy.hsl.hue) < 1.0 / 360)
    }
    @Test func alreadyBrightColorIsUnchanged() {
        let yellow = RGBAColor(red: 1, green: 0.85, blue: 0.2)
        #expect(yellow.adjustedForBlackBackground() == yellow)
    }
}
