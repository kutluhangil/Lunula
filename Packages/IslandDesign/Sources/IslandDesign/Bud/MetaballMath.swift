import CoreGraphics
import Foundation

public enum MetaballMath {
    public static let maxBlur: CGFloat = 6

    /// maxBlur × sin(π·p): zero at both ends, peak at the midpoint, never negative on spring overshoot.
    public static func blurRadius(progress: Double) -> CGFloat {
        maxBlur * CGFloat(max(0, sin(Double.pi * progress)))
    }

    public static func bubbleRect(progress: Double, from: CGRect, to: CGRect) -> CGRect {
        let p = CGFloat(progress)
        return CGRect(
            x: from.minX + (to.minX - from.minX) * p,
            y: from.minY + (to.minY - from.minY) * p,
            width: from.width + (to.width - from.width) * p,
            height: from.height + (to.height - from.height) * p)
    }
}
