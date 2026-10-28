import CoreGraphics

public struct HaloStyleValues: Equatable, Sendable {
    public var keyLineWidth: CGFloat
    public var keyLineOpacity: Double
    public var glowOpacity: Double
    public var glowRadius: CGFloat
    public var breathes: Bool
    public var pulses: Bool
}

public enum HaloStyle {
    public static let glowRadius: CGFloat = 14

    public static func resolve(_ state: HaloState, accessibility a: HaloAccessibility) -> HaloStyleValues {
        let scale = state.intensityScale
        var glow: Double
        var breathing = false
        var pulse = false
        switch state.mode {
        case .off:
            return HaloStyleValues(
                keyLineWidth: 0, keyLineOpacity: 0, glowOpacity: 0, glowRadius: glowRadius, breathes: false,
                pulses: false)
        case .ambient(let b):
            glow = HaloLevel.ambient.intensity * scale
            breathing = b && !a.reduceMotion && !a.lowPowerMode
        case .progress, .warming, .fill:
            glow = HaloLevel.active.intensity * scale
        case .pulse:
            pulse = !a.reduceMotion
            glow = (pulse ? HaloLevel.alert : HaloLevel.active).intensity * scale
        }
        if a.reduceTransparency { glow = 0 }
        // Nothing invisible animates.
        return HaloStyleValues(
            keyLineWidth: a.increaseContrast ? 1.5 : 1, keyLineOpacity: a.increaseContrast ? 0.6 : 0.35,
            glowOpacity: glow, glowRadius: glowRadius, breathes: breathing && glow > 0, pulses: pulse && glow > 0)
    }
}
