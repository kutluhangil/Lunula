import Foundation

extension RGBAColor {
    public static let black = RGBAColor(red: 0, green: 0, blue: 0)
    public static let white = RGBAColor(red: 1, green: 1, blue: 1)

    /// WCAG 2.x relative luminance (sRGB).
    public var relativeLuminance: Double {
        func linear(_ c: Double) -> Double { c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    public func contrastRatio(with other: RGBAColor) -> Double {
        let a = relativeLuminance
        let b = other.relativeLuminance
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    /// All components in 0...1 (hue is a fraction of a turn, not degrees).
    public var hsl: (hue: Double, saturation: Double, lightness: Double) {
        let maxC = max(red, green, blue)
        let minC = min(red, green, blue)
        let delta = maxC - minC
        let lightness = (maxC + minC) / 2
        guard delta > 0 else { return (0, 0, lightness) }
        let saturation = delta / (1 - abs(2 * lightness - 1))
        let sector: Double
        switch maxC {
        case red: sector = ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
        case green: sector = (blue - red) / delta + 2
        default: sector = (red - green) / delta + 4
        }
        let hue = sector / 6
        return (hue < 0 ? hue + 1 : hue, saturation, lightness)
    }

    public init(hue: Double, saturation: Double, lightness: Double, alpha: Double = 1) {
        let chroma = (1 - abs(2 * lightness - 1)) * saturation
        let h6 = (hue - hue.rounded(.down)) * 6
        let x = chroma * (1 - abs(h6.truncatingRemainder(dividingBy: 2) - 1))
        let (r, g, b): (Double, Double, Double)
        switch Int(h6) {
        case 0: (r, g, b) = (chroma, x, 0)
        case 1: (r, g, b) = (x, chroma, 0)
        case 2: (r, g, b) = (0, chroma, x)
        case 3: (r, g, b) = (0, x, chroma)
        case 4: (r, g, b) = (x, 0, chroma)
        default: (r, g, b) = (chroma, 0, x)
        }
        let m = lightness - chroma / 2
        self.init(red: r + m, green: g + m, blue: b + m, alpha: alpha)
    }

    /// Raises HSL lightness in 0.02 steps (cap 0.9) until contrast against black reaches the target.
    public func adjustedForBlackBackground(minimumContrast: Double = 3.0) -> RGBAColor {
        guard contrastRatio(with: .black) < minimumContrast else { return self }
        let (h, s, l) = hsl
        var lightness = l
        while lightness < 0.9 {
            lightness = min(lightness + 0.02, 0.9)
            let candidate = RGBAColor(hue: h, saturation: s, lightness: lightness, alpha: alpha)
            if candidate.contrastRatio(with: .black) >= minimumContrast { return candidate }
        }
        return RGBAColor(hue: h, saturation: s, lightness: 0.9, alpha: alpha)
    }
}
