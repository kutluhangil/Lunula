import IslandCore
import SwiftUI

/// Elastic water-droplet island outline that preserves exact `IslandShape` resting geometry and keeps the top
/// edge flush with the screen bezel on notched displays while allowing subtle lateral lean and meniscus sag.
public struct FluidIslandShape: Shape, Sendable {
    public var shoulderRadius: CGFloat
    public var cornerRadius: CGFloat
    public var topCornerRadius: CGFloat
    public var pullX: CGFloat
    public var pullY: CGFloat
    public var focusX: CGFloat

    public init(
        shoulderRadius: CGFloat,
        cornerRadius: CGFloat,
        topCornerRadius: CGFloat = 0,
        pullX: CGFloat = 0,
        pullY: CGFloat = 0,
        focusX: CGFloat = 0.5
    ) {
        self.shoulderRadius = shoulderRadius
        self.cornerRadius = cornerRadius
        self.topCornerRadius = topCornerRadius
        self.pullX = pullX
        self.pullY = pullY
        self.focusX = focusX
    }

    public init(base: IslandShape, tension: DropletTension = .zero) {
        self.init(
            shoulderRadius: base.shoulderRadius,
            cornerRadius: base.cornerRadius,
            topCornerRadius: base.topCornerRadius,
            pullX: CGFloat(tension.pullX),
            pullY: CGFloat(tension.pullY),
            focusX: CGFloat(tension.focusX)
        )
    }

    public typealias AnimatableData = AnimatablePair<
        AnimatablePair<CGFloat, CGFloat>,
        AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>>
    >

    public var animatableData: AnimatableData {
        get {
            AnimatablePair(
                AnimatablePair(shoulderRadius, cornerRadius),
                AnimatablePair(pullX, AnimatablePair(pullY, focusX))
            )
        }
        set {
            shoulderRadius = newValue.first.first
            cornerRadius = newValue.first.second
            pullX = newValue.second.first
            pullY = newValue.second.second.first
            focusX = newValue.second.second.second
        }
    }

    public func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0 else { return Path() }

        if abs(pullX) < 0.05 && abs(pullY) < 0.05 {
            return IslandShape(
                shoulderRadius: shoulderRadius,
                cornerRadius: cornerRadius,
                topCornerRadius: topCornerRadius
            ).path(in: rect)
        }

        let s = max(0, min(shoulderRadius, rect.height, rect.width / 4))
        let dx = min(max(pullX, -8), 8)
        let dy = min(max(pullY, 0), 6.5)
        let clampedFocus = min(max(focusX, 0.15), 0.85)

        if s > 0 {
            return notchedDeformedPath(in: rect, shoulder: s, pullX: dx, pullY: dy, focusX: clampedFocus)
        } else {
            return pillDeformedPath(in: rect, pullX: dx, pullY: dy, focusX: clampedFocus)
        }
    }

    private func notchedDeformedPath(
        in rect: CGRect,
        shoulder s: CGFloat,
        pullX dx: CGFloat,
        pullY dy: CGFloat,
        focusX: CGFloat
    ) -> Path {
        let kappa: CGFloat = 0.5522847498
        let bodyWidth = max(0, rect.width - 2 * s)
        let c = max(0, min(cornerRadius, bodyWidth / 2, max(0, rect.height - s)))
        let lean = dx * 0.55

        let leftTopX = rect.minX + s
        let rightTopX = rect.maxX - s
        let wallTopY = rect.minY + s

        let leftBottomX = leftTopX + lean
        let rightBottomX = rightTopX + lean
        let cornerStartY = rect.maxY - c
        let wallMidY = (wallTopY + cornerStartY) * 0.5

        let leftSpanX = leftBottomX + c
        let rightSpanX = rightBottomX - c
        let desiredPeakX = rect.minX + rect.width * focusX
        let peakX =
            leftSpanX <= rightSpanX
            ? min(max(desiredPeakX, leftSpanX), rightSpanX)
            : (leftSpanX + rightSpanX) * 0.5
        let peakY = rect.maxY + dy

        let sk = s * kappa
        let ck = c * kappa

        var path = Path()
        // Top edge stays strictly pinned to y = rect.minY from minX to maxX.
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        // Right concave shoulder flaring inward from the bezel.
        path.addCurve(
            to: CGPoint(x: rightTopX, y: wallTopY),
            control1: CGPoint(x: rect.maxX - sk, y: rect.minY),
            control2: CGPoint(x: rightTopX, y: wallTopY - sk)
        )

        // Right wall leaning subtly toward the cursor side.
        path.addCurve(
            to: CGPoint(x: rightBottomX, y: cornerStartY),
            control1: CGPoint(x: rightTopX, y: wallMidY),
            control2: CGPoint(x: rightBottomX, y: wallMidY)
        )

        // Bottom-right rounded corner.
        if c > 0 {
            path.addCurve(
                to: CGPoint(x: rightSpanX, y: rect.maxY),
                control1: CGPoint(x: rightBottomX, y: cornerStartY + ck),
                control2: CGPoint(x: rightSpanX + ck, y: rect.maxY)
            )
        }

        // Smooth C1 cubic Bezier meniscus bulge along the bottom edge peaking at (peakX, rect.maxY + pullY).
        let rightHalfSpan = (rightSpanX - peakX) * 0.5
        path.addCurve(
            to: CGPoint(x: peakX, y: peakY),
            control1: CGPoint(x: rightSpanX - rightHalfSpan, y: rect.maxY),
            control2: CGPoint(x: peakX + rightHalfSpan, y: peakY)
        )
        let leftHalfSpan = (peakX - leftSpanX) * 0.5
        path.addCurve(
            to: CGPoint(x: leftSpanX, y: rect.maxY),
            control1: CGPoint(x: peakX - leftHalfSpan, y: peakY),
            control2: CGPoint(x: leftSpanX + leftHalfSpan, y: rect.maxY)
        )

        // Bottom-left rounded corner.
        if c > 0 {
            path.addCurve(
                to: CGPoint(x: leftBottomX, y: cornerStartY),
                control1: CGPoint(x: leftSpanX - ck, y: rect.maxY),
                control2: CGPoint(x: leftBottomX, y: cornerStartY + ck)
            )
        }

        // Left wall returning up to the left shoulder.
        path.addCurve(
            to: CGPoint(x: leftTopX, y: wallTopY),
            control1: CGPoint(x: leftBottomX, y: wallMidY),
            control2: CGPoint(x: leftTopX, y: wallMidY)
        )

        // Left concave shoulder flaring back out to the top bezel.
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY),
            control1: CGPoint(x: leftTopX, y: wallTopY - sk),
            control2: CGPoint(x: rect.minX + sk, y: rect.minY)
        )

        path.closeSubpath()
        return path
    }

    private func pillDeformedPath(
        in rect: CGRect,
        pullX dx: CGFloat,
        pullY dy: CGFloat,
        focusX: CGFloat
    ) -> Path {
        let kappa: CGFloat = 0.5522847498
        let c = max(0, min(cornerRadius, rect.width / 2, rect.height / 2))
        let topC = max(0, min(topCornerRadius > 0 ? topCornerRadius : cornerRadius, rect.width / 2, rect.height / 2))

        let topShiftX = dx * 0.35
        let bottomShiftX = dx * 0.65
        let topSagY = dy * 0.35

        let topLeftX = rect.minX + topShiftX
        let topRightX = rect.maxX + topShiftX
        let bottomLeftX = rect.minX + bottomShiftX
        let bottomRightX = rect.maxX + bottomShiftX

        let topY = rect.minY + topSagY * 0.4
        let bottomY = rect.maxY

        let topSpanLeft = topLeftX + topC
        let topSpanRight = topRightX - topC
        let topPeakX =
            topSpanLeft <= topSpanRight
            ? min(max(rect.minX + rect.width * focusX + topShiftX, topSpanLeft), topSpanRight)
            : (topSpanLeft + topSpanRight) * 0.5
        let topPeakY = topY + topSagY * 0.6

        let bottomSpanLeft = bottomLeftX + c
        let bottomSpanRight = bottomRightX - c
        let bottomPeakX =
            bottomSpanLeft <= bottomSpanRight
            ? min(max(rect.minX + rect.width * focusX + bottomShiftX, bottomSpanLeft), bottomSpanRight)
            : (bottomSpanLeft + bottomSpanRight) * 0.5
        let bottomPeakY = bottomY + dy

        let tck = topC * kappa
        let bck = c * kappa
        let midY = (topY + topC + bottomY - c) * 0.5

        var path = Path()
        path.move(to: CGPoint(x: topSpanLeft, y: topY))

        // Top edge flexing gently toward the pull.
        let topLeftHalf = (topPeakX - topSpanLeft) * 0.5
        path.addCurve(
            to: CGPoint(x: topPeakX, y: topPeakY),
            control1: CGPoint(x: topSpanLeft + topLeftHalf, y: topY),
            control2: CGPoint(x: topPeakX - topLeftHalf, y: topPeakY)
        )
        let topRightHalf = (topSpanRight - topPeakX) * 0.5
        path.addCurve(
            to: CGPoint(x: topSpanRight, y: topY),
            control1: CGPoint(x: topPeakX + topRightHalf, y: topPeakY),
            control2: CGPoint(x: topSpanRight - topRightHalf, y: topY)
        )

        if topC > 0 {
            path.addCurve(
                to: CGPoint(x: topRightX, y: topY + topC),
                control1: CGPoint(x: topSpanRight + tck, y: topY),
                control2: CGPoint(x: topRightX, y: topY + topC - tck)
            )
        }

        path.addCurve(
            to: CGPoint(x: bottomRightX, y: bottomY - c),
            control1: CGPoint(x: topRightX, y: midY),
            control2: CGPoint(x: bottomRightX, y: midY)
        )

        if c > 0 {
            path.addCurve(
                to: CGPoint(x: bottomSpanRight, y: bottomY),
                control1: CGPoint(x: bottomRightX, y: bottomY - c + bck),
                control2: CGPoint(x: bottomSpanRight + bck, y: bottomY)
            )
        }

        let bottomRightHalf = (bottomSpanRight - bottomPeakX) * 0.5
        path.addCurve(
            to: CGPoint(x: bottomPeakX, y: bottomPeakY),
            control1: CGPoint(x: bottomSpanRight - bottomRightHalf, y: bottomY),
            control2: CGPoint(x: bottomPeakX + bottomRightHalf, y: bottomPeakY)
        )
        let bottomLeftHalf = (bottomPeakX - bottomSpanLeft) * 0.5
        path.addCurve(
            to: CGPoint(x: bottomSpanLeft, y: bottomY),
            control1: CGPoint(x: bottomPeakX - bottomLeftHalf, y: bottomPeakY),
            control2: CGPoint(x: bottomSpanLeft + bottomLeftHalf, y: bottomY)
        )

        if c > 0 {
            path.addCurve(
                to: CGPoint(x: bottomLeftX, y: bottomY - c),
                control1: CGPoint(x: bottomSpanLeft - bck, y: bottomY),
                control2: CGPoint(x: bottomLeftX, y: bottomY - c + bck)
            )
        }

        path.addCurve(
            to: CGPoint(x: topLeftX, y: topY + topC),
            control1: CGPoint(x: bottomLeftX, y: midY),
            control2: CGPoint(x: topLeftX, y: midY)
        )

        if topC > 0 {
            path.addCurve(
                to: CGPoint(x: topSpanLeft, y: topY),
                control1: CGPoint(x: topLeftX, y: topY + topC - tck),
                control2: CGPoint(x: topSpanLeft - tck, y: topY)
            )
        }

        path.closeSubpath()
        return path
    }
}

/// Specular surface-tension highlight following the cursor across a `FluidIslandShape`.
public struct DropletSpecularOverlay: View {
    public var tension: DropletTension
    public var shape: FluidIslandShape

    public init(tension: DropletTension, shape: FluidIslandShape) {
        self.tension = tension
        self.shape = shape
    }

    public var body: some View {
        if tension.intensity <= 0.01 {
            EmptyView()
        } else {
            let strength = min(max(tension.intensity, 0), 1)
            let clampedFocus = min(max(tension.focusX, 0), 1)
            let center = UnitPoint(x: clampedFocus, y: 0.75)
            let causticCenter = UnitPoint(x: clampedFocus, y: 0.92)

            ZStack {
                RadialGradient(
                    colors: [
                        .white.opacity(0.16 * strength),
                        .white.opacity(0.05 * strength),
                        .clear,
                    ],
                    center: center,
                    startRadius: 2,
                    endRadius: 140
                )
                RadialGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .white.opacity(0.14 * strength), location: 0.42),
                        .init(color: .white.opacity(0.05 * strength), location: 0.68),
                        .init(color: .clear, location: 1.0),
                    ],
                    center: causticCenter,
                    startRadius: 6,
                    endRadius: 86
                )
                shape.stroke(
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.10 * strength),
                            .white.opacity(0.28 * strength),
                        ],
                        startPoint: .top,
                        endPoint: UnitPoint(x: clampedFocus, y: 1.0)
                    ),
                    lineWidth: 1.2
                )
            }
            .clipShape(shape)
            .allowsHitTesting(false)
        }
    }
}
