import AppKit
import IslandCore
import SwiftUI
import Testing

@testable import IslandDesign

@Suite struct DesignTokenTests {
    @Test func obsidianIsPureOpaqueBlack() throws {
        #expect(Palette.obsidianRGBA == RGBAColor(red: 0, green: 0, blue: 0, alpha: 1))
        let c = try #require(NSColor(Palette.obsidian).usingColorSpace(.sRGB))
        #expect(c.redComponent == 0 && c.greenComponent == 0 && c.blueComponent == 0 && c.alphaComponent == 1)
    }
    @Test func smallestTypeIs11pt() { #expect(TypeToken.allCases.map(\.size).min() == 11) }
    @Test func typeStylesMatchSpecTable() {
        typealias Row = (TypeToken, CGFloat, Font.Weight, Bool, Bool)
        let table: [Row] = [
            (.numeralLarge, 28, .semibold, true, true),
            (.numeralCompact, 13, .semibold, true, true),
            (.title, 15, .semibold, false, false),
            (.body, 13, .medium, false, false),
            (.caption, 11, .medium, false, false),
        ]
        for (token, size, weight, rounded, mono) in table {
            #expect(token.size == size && token.weight == weight, "\(token)")
            #expect(token.isRounded == rounded && token.monospacedDigits == mono, "\(token)")
        }
    }
    @Test func transitionsRespectBounceAndDurationLimits() {
        for t in MotionToken.transitions { #expect(t.spec.bounce <= 0.12 && t.spec.duration <= 2.0, "\(t)") }
    }
    @Test func motionValuesMatchSpec() {
        #expect(MotionToken.open.spec == MotionSpec(duration: 0.45, bounce: 0.10))
        #expect(MotionToken.close.spec == MotionSpec(duration: 0.35, bounce: 0))
        #expect(MotionToken.peek.spec == MotionSpec(duration: 0.30, bounce: 0.08))
        #expect(MotionToken.morph.spec == MotionSpec(duration: 0.40, bounce: 0.05))
    }
    @Test func reducedMotionUsesShortEase() {
        #expect(MotionToken.animation(.open, reduceMotion: true) == .easeInOut(duration: 0.2))
    }
    @Test func breathIsAFiveSecondCycle() {
        // Autoreversing: each half lasts duration / 2, so a full in-and-out breath is 5 s.
        let breath = Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)
        #expect(MotionToken.animation(.breath, reduceMotion: false) == breath)
    }
    @Test func haloIntensitiesMatchSpec() { #expect(HaloLevel.allCases.map(\.intensity) == [0, 0.16, 0.32, 0.55]) }
    @Test func cardRadiusIsConcentric() { #expect(Radii.card == 12) }
}
