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
    @Test func haloIntensitiesMatchSpec() { #expect(HaloLevel.allCases.map(\.intensity) == [0, 0.16, 0.32, 0.55]) }
    @Test func cardRadiusIsConcentric() { #expect(Radii.card == 12) }
}
