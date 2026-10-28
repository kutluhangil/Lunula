import AppKit
import IslandCore
import Testing

@testable import IslandDesign

@Suite struct HaloStyleTests {
    let red = RGBAColor(red: 1, green: 0, blue: 0)
    func warming(_ fraction: Double) -> RGBAColor {
        HaloStyle.resolve(.init(mode: .warming(fraction: fraction), color: red), accessibility: .standard).color
    }
    func isClose(_ a: RGBAColor, _ b: RGBAColor) -> Bool {
        [a.red - b.red, a.green - b.green, a.blue - b.blue, a.alpha - b.alpha].allSatisfy { abs($0) < 0.002 }
    }
    @Test func warmingInterpolatesFromNeutralToAmber() throws {
        let neutral = RGBAColor(red: 0xF5 / 255, green: 0xF5 / 255, blue: 0xF7 / 255)
        let o = try #require(NSColor.systemOrange.usingColorSpace(.sRGB))
        let amber = RGBAColor(red: o.redComponent, green: o.greenComponent, blue: o.blueComponent)
        let mid = RGBAColor(
            red: (neutral.red + amber.red) / 2, green: (neutral.green + amber.green) / 2,
            blue: (neutral.blue + amber.blue) / 2)
        #expect(isClose(warming(0), neutral))
        #expect(isClose(warming(1), amber))
        #expect(isClose(warming(0.5), mid))
        #expect(warming(-1) == warming(0) && warming(2) == warming(1))
    }
    @Test func nonWarmingModesUseStateColor() {
        #expect(
            HaloStyle.resolve(.init(mode: .ambient(breathing: false), color: red), accessibility: .standard).color
                == red)
    }
    @Test func ambientIntensityIs016() {
        #expect(
            HaloStyle.resolve(.init(mode: .ambient(breathing: true), color: red), accessibility: .standard).glowOpacity
                == 0.16)
    }
    @Test func alertPeakIs055() {
        #expect(HaloStyle.resolve(.init(mode: .pulse, color: red), accessibility: .standard).glowOpacity == 0.55)
    }
    @Test func intensityScaleMultiplies() {
        #expect(
            HaloStyle.resolve(
                .init(mode: .ambient(breathing: false), color: red, intensityScale: 0.5), accessibility: .standard
            ).glowOpacity == 0.08)
    }
    @Test func reduceMotionDisablesBreathAndPulse() {
        var a = HaloAccessibility.standard
        a.reduceMotion = true
        #expect(!HaloStyle.resolve(.init(mode: .ambient(breathing: true), color: red), accessibility: a).breathes)
        #expect(!HaloStyle.resolve(.init(mode: .pulse, color: red), accessibility: a).pulses)
    }
    @Test func lowPowerDisablesBreath() {
        var a = HaloAccessibility.standard
        a.lowPowerMode = true
        #expect(!HaloStyle.resolve(.init(mode: .ambient(breathing: true), color: red), accessibility: a).breathes)
    }
    @Test func reduceTransparencyRemovesGlow() {
        var a = HaloAccessibility.standard
        a.reduceTransparency = true
        #expect(HaloStyle.resolve(.init(mode: .pulse, color: red), accessibility: a).glowOpacity == 0)
    }
    @Test func increaseContrastThickensKeyLine() {
        var a = HaloAccessibility.standard
        a.increaseContrast = true
        let v = HaloStyle.resolve(.init(mode: .ambient(breathing: false), color: red), accessibility: a)
        #expect(v.keyLineWidth == 1.5 && v.keyLineOpacity == 0.6)
    }
    @Test func offIsFullyDark() {
        let v = HaloStyle.resolve(.off, accessibility: .standard)
        #expect(v.glowOpacity == 0 && v.keyLineOpacity == 0 && !v.breathes)
    }
}
