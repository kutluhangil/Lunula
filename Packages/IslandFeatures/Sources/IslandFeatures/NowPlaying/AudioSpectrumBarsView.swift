import IslandCore
import IslandDesign
import SwiftUI

public struct AudioSpectrumBarsView: View {
    public static let barCount = 8
    private static let reducedMotionProfile: [Double] = [0.38, 0.58, 0.74, 0.52, 0.68, 0.46, 0.60, 0.36]

    public let levels: [Double]
    public let isPlaying: Bool
    public var accent: RGBAColor?
    public var barWidth: CGFloat
    public var height: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        levels: [Double],
        isPlaying: Bool,
        accent: RGBAColor? = nil,
        barWidth: CGFloat = 3,
        height: CGFloat = 22
    ) {
        self.levels = levels
        self.isPlaying = isPlaying
        self.accent = accent
        self.barWidth = barWidth
        self.height = height
    }

    public var body: some View {
        let resolved = resolvedLevels
        let spacing = max(2, (barWidth * 0.67).rounded())
        HStack(alignment: .center, spacing: spacing) {
            ForEach(0..<Self.barCount, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(barFill)
                    .frame(
                        width: barWidth,
                        height: barHeight(for: resolved[index])
                    )
            }
        }
        .frame(height: height)
        .opacity(isPlaying ? 1.0 : 0.42)
        .animation(
            reduceMotion ? nil : .smooth(duration: 0.09),
            value: resolved
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(isPlaying ? "nowPlaying.playing" : "nowPlaying.paused", bundle: .module))
    }

    private var resolvedLevels: [Double] {
        guard isPlaying else {
            return Array(repeating: 0, count: Self.barCount)
        }
        if reduceMotion {
            return Self.reducedMotionProfile
        }
        return (0..<Self.barCount).map { index in
            guard index < levels.count else { return 0.16 }
            return min(max(levels[index], 0.0), 1.0)
        }
    }

    private func barHeight(for level: Double) -> CGFloat {
        guard isPlaying else { return barWidth }
        let usable = max(barWidth, height)
        return max(barWidth, barWidth + CGFloat(level) * (usable - barWidth))
    }

    private var barFill: LinearGradient {
        let primaryTint = accent.map(Palette.color) ?? Palette.textPrimary
        let secondaryTint = accent != nil ? Palette.textPrimary.opacity(0.88) : Palette.textPrimary.opacity(0.72)
        return LinearGradient(
            colors: [primaryTint, secondaryTint],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
