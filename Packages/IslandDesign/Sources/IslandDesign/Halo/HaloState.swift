import Foundation
import IslandCore

public enum HaloMode: Equatable, Sendable {
    case off
    case ambient(breathing: Bool)
    case progress(fraction: Double, endsAt: Date?)
    case warming(fraction: Double)
    case fill(fraction: Double)
    case pulse
}

public struct HaloState: Equatable, Sendable {
    public var mode: HaloMode
    public var color: RGBAColor
    public var intensityScale: Double

    public init(mode: HaloMode, color: RGBAColor, intensityScale: Double = 1) {
        self.mode = mode
        self.color = color
        self.intensityScale = intensityScale
    }

    public static let off = HaloState(mode: .off, color: RGBAColor(red: 0, green: 0, blue: 0))
}

public struct HaloAccessibility: Equatable, Sendable {
    public var reduceMotion = false
    public var reduceTransparency = false
    public var increaseContrast = false
    public var lowPowerMode = false

    public init(
        reduceMotion: Bool = false, reduceTransparency: Bool = false, increaseContrast: Bool = false,
        lowPowerMode: Bool = false
    ) {
        self.reduceMotion = reduceMotion
        self.reduceTransparency = reduceTransparency
        self.increaseContrast = increaseContrast
        self.lowPowerMode = lowPowerMode
    }

    public static let standard = HaloAccessibility()
}
