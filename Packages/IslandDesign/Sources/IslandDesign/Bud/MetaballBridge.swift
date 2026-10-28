import SwiftUI

/// Gooey island-to-bubble bridge. Use only during the 0.55 s transition; steady state draws plain shapes.
public struct MetaballBridge: View, Animatable {
    public var islandRect: CGRect
    public var bubbleStart: CGRect
    public var bubbleEnd: CGRect
    public var progress: Double
    public var islandCornerRadius: CGFloat

    public init(
        islandRect: CGRect, bubbleStart: CGRect, bubbleEnd: CGRect, progress: Double, islandCornerRadius: CGFloat
    ) {
        self.islandRect = islandRect
        self.bubbleStart = bubbleStart
        self.bubbleEnd = bubbleEnd
        self.progress = progress
        self.islandCornerRadius = islandCornerRadius
    }

    nonisolated public var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    public var body: some View {
        Canvas { context, _ in
            context.addFilter(.alphaThreshold(min: 0.5, color: .black))
            context.addFilter(.blur(radius: MetaballMath.blurRadius(progress: progress)))
            context.drawLayer { layer in
                layer.fill(
                    Path(roundedRect: islandRect, cornerRadius: islandCornerRadius), with: .color(.black))
                let bubble = MetaballMath.bubbleRect(progress: progress, from: bubbleStart, to: bubbleEnd)
                layer.fill(Path(ellipseIn: bubble), with: .color(.black))
            }
        }
    }
}
