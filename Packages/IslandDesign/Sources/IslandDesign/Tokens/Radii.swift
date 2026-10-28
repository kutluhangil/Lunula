import CoreGraphics

public enum Radii {
    public static let closedShoulder: CGFloat = 6
    public static let closedCorner: CGFloat = 10
    public static let expandedShoulder: CGFloat = 12
    public static let expandedCorner: CGFloat = 26
    public static let artworkSmall: CGFloat = 6
    public static let artworkLarge: CGFloat = 12

    /// Concentric inner radius: outer radius minus the padding between the shapes.
    public static func inner(outer: CGFloat, padding: CGFloat) -> CGFloat { max(0, outer - padding) }

    public static var card: CGFloat { inner(outer: expandedCorner, padding: Spacing.expandedPadding) }
}
