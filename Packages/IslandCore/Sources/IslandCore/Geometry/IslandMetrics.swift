import Foundation

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

public enum IslandSizeRequest: Equatable, Sendable {
    case idle
    /// Hover "breath" invite while no activity is shown: +8 pt on every side (spec 4.4).
    case invite
    case compact(wing: CGFloat)
    case peek
    case expanded(width: CGFloat, bodyHeight: CGFloat)
}

public enum IslandMetrics {
    public static let wingMax: CGFloat = 64
    public static let peekWing: CGFloat = 72
    public static let peekMinWidth: CGFloat = 340
    public static let peekExtraHeight: CGFloat = 30
    public static let expandedWidthRange: ClosedRange<CGFloat> = 520...600
    public static let expandedBodyRange: ClosedRange<CGFloat> = 128...176
    public static let bubbleGap: CGFloat = 8
    public static let panelSize = CGSize(width: 760, height: 300)

    public static func size(for request: IslandSizeRequest, notch: NotchMetrics) -> CGSize {
        let n = notch.size
        switch request {
        case .idle:
            return n
        case .invite:
            return CGSize(width: n.width + 16, height: n.height)
        case .compact(let wing):
            return CGSize(width: n.width + 2 * min(max(wing, 0), wingMax), height: n.height)
        case .peek:
            return CGSize(width: max(n.width + 2 * peekWing, peekMinWidth), height: n.height + peekExtraHeight)
        case .expanded(let width, let bodyHeight):
            return CGSize(
                width: min(max(width, expandedWidthRange.lowerBound), expandedWidthRange.upperBound),
                height: n.height + min(max(bodyHeight, expandedBodyRange.lowerBound), expandedBodyRange.upperBound))
        }
    }

    public static func islandRect(size: CGSize, notch: NotchMetrics) -> CGRect {
        CGRect(
            x: notch.rect.midX - size.width / 2, y: notch.rect.maxY - size.height, width: size.width,
            height: size.height)
    }

    /// Square notch-height bubble to the right of the primary island, `index` slots over.
    public static func bubbleRect(index: Int, primary: CGRect, notch: NotchMetrics) -> CGRect {
        let side = notch.size.height
        return CGRect(
            x: primary.maxX + bubbleGap + CGFloat(index) * (side + bubbleGap), y: primary.maxY - side, width: side,
            height: side)
    }

    public static func hotZone(around rect: CGRect) -> CGRect {
        CGRect(x: rect.minX - 10, y: rect.minY - 6, width: rect.width + 20, height: rect.height + 6)
    }

    public static func panelFrame(notch: NotchMetrics, screen: ScreenDescriptor) -> CGRect {
        let w = panelSize.width
        let x = min(max(notch.rect.midX - w / 2, screen.frame.minX), screen.frame.maxX - w)
        return CGRect(x: x, y: screen.frame.maxY - panelSize.height, width: w, height: panelSize.height)
    }
}
