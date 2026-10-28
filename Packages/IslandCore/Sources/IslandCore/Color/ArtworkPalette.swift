public struct WeightedColor: Equatable, Sendable {
    public var color: RGBAColor
    public var weight: Double

    public init(color: RGBAColor, weight: Double) {
        self.color = color
        self.weight = weight
    }
}

public enum ArtworkPalette {
    /// Picks the dominant saturated color, made legible on black. `nil` when the artwork has no usable accent.
    public static func accent(from candidates: [WeightedColor]) -> RGBAColor? {
        candidates
            .filter { $0.color.relativeLuminance >= 0.02 && $0.color.hsl.saturation >= 0.18 }
            .max { $0.weight * (0.35 + $0.color.hsl.saturation) < $1.weight * (0.35 + $1.color.hsl.saturation) }?
            .color.adjustedForBlackBackground(minimumContrast: 3.0)
    }
}
