import IslandCore
import Testing

@testable import IslandDesign

@Suite struct HaloStyleTests {
    let red = RGBAColor(red: 1, green: 0, blue: 0)
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
