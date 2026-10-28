import AppKit
import IslandCore
import SwiftUI

public struct HaloStyleValues: Equatable, Sendable {
    public var color: RGBAColor
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
        var color = state.color
        var glow: Double
        var breathing = false
        var pulse = false
        switch state.mode {
        case .off:
            return HaloStyleValues(
                color: color, keyLineWidth: 0, keyLineOpacity: 0, glowOpacity: 0, glowRadius: glowRadius,
                breathes: false, pulses: false)
        case .ambient(let b):
            glow = HaloLevel.ambient.intensity * scale
            breathing = b && !a.reduceMotion && !a.lowPowerMode
        case .warming(let fraction):
            // Meeting approaching: warms from neutral to amber (spec §6.4); the spec has no amber token.
            color = mix(rgba(Palette.textPrimary), rgba(Palette.signalOrange), min(max(fraction, 0), 1))
            glow = HaloLevel.active.intensity * scale
        case .progress, .fill:
            glow = HaloLevel.active.intensity * scale
        case .pulse:
            pulse = !a.reduceMotion
            glow = (pulse ? HaloLevel.alert : HaloLevel.active).intensity * scale
        }
        if a.reduceTransparency { glow = 0 }
        // Nothing invisible animates.
        return HaloStyleValues(
            color: color, keyLineWidth: a.increaseContrast ? 1.5 : 1, keyLineOpacity: a.increaseContrast ? 0.6 : 0.35,
            glowOpacity: glow, glowRadius: glowRadius, breathes: breathing && glow > 0, pulses: pulse && glow > 0)
    }

    private static func rgba(_ color: Color) -> RGBAColor {
        let c = NSColor(color).usingColorSpace(.sRGB) ?? .white
        return RGBAColor(red: c.redComponent, green: c.greenComponent, blue: c.blueComponent, alpha: c.alphaComponent)
    }

    private static func mix(_ a: RGBAColor, _ b: RGBAColor, _ t: Double) -> RGBAColor {
        RGBAColor(
            red: a.red + (b.red - a.red) * t, green: a.green + (b.green - a.green) * t,
            blue: a.blue + (b.blue - a.blue) * t, alpha: a.alpha + (b.alpha - a.alpha) * t)
    }
}
