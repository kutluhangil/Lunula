import IslandCore
import SwiftUI

/// Gooey island-to-bubble bridge. Use only during the 0.55 s transition; steady state draws plain shapes.
/// Draws a simplified island (no shoulders) for the bud transition only; overlay it on the real island, never replace it.
public struct MetaballBridge: View, Animatable {
    public var islandRect: CGRect
    public var bubbleStart: CGRect
    public var bubbleEnd: CGRect
    public var progress: Double
    public var islandCornerRadius: CGFloat
    public var surfaceMaterial: IslandSurfaceMaterial = .obsidian

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    public init(
        islandRect: CGRect,
        bubbleStart: CGRect,
        bubbleEnd: CGRect,
        progress: Double,
        islandCornerRadius: CGFloat,
        surfaceMaterial: IslandSurfaceMaterial = .obsidian
    ) {
        self.islandRect = islandRect
        self.bubbleStart = bubbleStart
        self.bubbleEnd = bubbleEnd
        self.progress = progress
        self.islandCornerRadius = islandCornerRadius
        self.surfaceMaterial = surfaceMaterial
    }

    nonisolated public var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    public var body: some View {
        let allowGlass = surfaceMaterial == .liquidGlass && !reduceTransparency && contrast != .increased
        let bridgeColor = allowGlass ? Color(white: 0.14, opacity: 0.78) : .black
        let bubble = MetaballMath.bubbleRect(progress: progress, from: bubbleStart, to: bubbleEnd)

        Canvas { context, _ in
            context.addFilter(.alphaThreshold(min: 0.5, color: bridgeColor))
            context.addFilter(.blur(radius: MetaballMath.blurRadius(progress: progress)))
            context.drawLayer { layer in
                layer.fill(
                    Path(roundedRect: islandRect, cornerRadius: islandCornerRadius), with: .color(.black))
                layer.fill(Path(ellipseIn: bubble), with: .color(.black))
            }
        }
        .overlay {
            if allowGlass {
                Path(ellipseIn: bubble)
                    .stroke(.white.opacity(0.18), lineWidth: 0.75)
            }
        }
    }
}
