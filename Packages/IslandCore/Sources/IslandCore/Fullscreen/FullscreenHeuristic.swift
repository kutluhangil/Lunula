import Foundation

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

public struct WindowInfo: Equatable, Sendable {
    public var ownerPID: Int32
    public var layer: Int
    /// Quartz coordinates: origin top-left.
    public var bounds: CGRect
    public var isOnscreen: Bool

    public init(ownerPID: Int32, layer: Int, bounds: CGRect, isOnscreen: Bool) {
        self.ownerPID = ownerPID
        self.layer = layer
        self.bounds = bounds
        self.isOnscreen = isOnscreen
    }
}

public enum FullscreenHeuristic {
    public static let mainMenuLayer = 24
    private static let tolerance: CGFloat = 1

    public static func isFullscreen(
        windows: [WindowInfo], frontmostPID: Int32, screen: ScreenDescriptor, primaryScreenHeight: CGFloat
    ) -> Bool {
        let quartzY = primaryScreenHeight - screen.frame.maxY
        let menuBand = CGRect(x: screen.frame.minX, y: quartzY, width: screen.frame.width, height: screen.menuBarHeight)
        let menuBarVisible = windows.contains {
            guard $0.layer == mainMenuLayer, $0.isOnscreen else { return false }
            let overlap = $0.bounds.intersection(menuBand)
            return !overlap.isNull && overlap.width > 0 && overlap.height > 0
        }
        if menuBarVisible { return false }
        let required = CGRect(
            x: screen.frame.minX, y: quartzY + screen.safeAreaTop,
            width: screen.frame.width, height: screen.frame.height - screen.safeAreaTop
        ).insetBy(dx: tolerance, dy: tolerance)
        return windows.contains {
            $0.ownerPID == frontmostPID && $0.layer == 0 && $0.isOnscreen && $0.bounds.contains(required)
        }
    }
}
