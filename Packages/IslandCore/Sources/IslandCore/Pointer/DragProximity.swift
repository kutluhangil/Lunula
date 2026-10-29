import Foundation

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// A file drag near the top of a screen pulls the shelf open (the "magnet").
public enum DragProximity {
    public static let band: CGFloat = 120

    /// AppKit coordinates (y up): inside the screen and within `band` of its top edge.
    public static func isApproaching(point: CGPoint, screenFrame: CGRect) -> Bool {
        screenFrame.contains(point) && point.y >= screenFrame.maxY - band
    }
}
