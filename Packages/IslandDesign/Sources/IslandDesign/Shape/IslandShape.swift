import SwiftUI

/// Island outline: a body with continuous bottom corners and concave shoulders that flare into the top edge.
public struct IslandShape: Shape, Sendable {
    public var shoulderRadius: CGFloat
    public var cornerRadius: CGFloat

    public init(shoulderRadius: CGFloat, cornerRadius: CGFloat) {
        self.shoulderRadius = shoulderRadius
        self.cornerRadius = cornerRadius
    }

    public static let closed = IslandShape(shoulderRadius: Radii.closedShoulder, cornerRadius: Radii.closedCorner)
    public static let expanded = IslandShape(shoulderRadius: Radii.expandedShoulder, cornerRadius: Radii.expandedCorner)

    public var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(shoulderRadius, cornerRadius) }
        set { (shoulderRadius, cornerRadius) = (newValue.first, newValue.second) }
    }

    public func path(in rect: CGRect) -> Path {
        let s = max(0, min(shoulderRadius, rect.height, rect.width / 4))
        let body = rect.insetBy(dx: s, dy: 0)
        let c = max(0, min(cornerRadius, body.width / 2, body.height))
        let bodyPath = UnevenRoundedRectangle(
            topLeadingRadius: 0, bottomLeadingRadius: c, bottomTrailingRadius: c, topTrailingRadius: 0,
            style: .continuous
        ).path(in: body).cgPath
        guard s > 0 else { return Path(bodyPath) }

        // Square minus a circle centred on the body edge leaves the concave flare.
        func shoulder(square: CGRect, circleCenter: CGPoint) -> CGPath {
            let circle = CGPath(
                ellipseIn: CGRect(x: circleCenter.x - s, y: circleCenter.y - s, width: 2 * s, height: 2 * s),
                transform: nil)
            return CGPath(rect: square, transform: nil).subtracting(circle)
        }
        let left = shoulder(
            square: CGRect(x: rect.minX, y: rect.minY, width: s, height: s),
            circleCenter: CGPoint(x: rect.minX, y: rect.minY + s))
        let right = shoulder(
            square: CGRect(x: rect.maxX - s, y: rect.minY, width: s, height: s),
            circleCenter: CGPoint(x: rect.maxX, y: rect.minY + s))
        // Union into one outline; adjacent sub-paths would leave a seam under edge antialiasing.
        return Path(bodyPath.union(left).union(right))
    }
}

#Preview {
    VStack(spacing: 24) {
        IslandShape.closed.fill(.black).frame(width: 148, height: 32)
        IslandShape.expanded.fill(.black).frame(width: 300, height: 80)
    }
    .scaleEffect(4)
    .frame(width: 1300, height: 600)
    .background(.white)
}
