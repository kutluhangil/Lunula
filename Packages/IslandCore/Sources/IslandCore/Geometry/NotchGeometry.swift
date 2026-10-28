import Foundation

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

public struct NotchMetrics: Equatable, Sendable {
    public var rect: CGRect
    public var hasHardwareNotch: Bool
    public var size: CGSize { rect.size }

    public init(rect: CGRect, hasHardwareNotch: Bool) {
        self.rect = rect
        self.hasHardwareNotch = hasHardwareNotch
    }
}

public enum NotchGeometry {
    public static let pillBaseWidth: CGFloat = 180

    /// Hardware notch when both auxiliary areas exist, otherwise a pill centered in the menu bar band.
    public static func metrics(for screen: ScreenDescriptor) -> NotchMetrics {
        if let left = screen.auxiliaryTopLeft, let right = screen.auxiliaryTopRight {
            let width = screen.frame.width - left.width - right.width
            let rect = CGRect(
                x: left.maxX, y: screen.frame.maxY - screen.safeAreaTop, width: width, height: screen.safeAreaTop)
            return NotchMetrics(rect: rect, hasHardwareNotch: true)
        }
        let height = min(max(screen.menuBarHeight - 6, 22), 30)
        let maxY = screen.frame.maxY - (screen.menuBarHeight - height) / 2
        let rect = CGRect(
            x: screen.frame.midX - pillBaseWidth / 2, y: maxY - height, width: pillBaseWidth, height: height)
        return NotchMetrics(rect: rect, hasHardwareNotch: false)
    }
}
