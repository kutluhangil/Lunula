import IslandCore
import SwiftUI

/// Renders the outer shell material of the island (`#000000` obsidian or macOS 26 Liquid Glass)
/// while keeping any physical MacBook camera notch masked in pure `#000000`.
public struct IslandShellBackground<S: Shape>: View {
    public var material: IslandSurfaceMaterial
    public var shape: S
    public var notchSize: CGSize
    public var hasHardwareNotch: Bool
    public var artworkTint: RGBAColor?
    public var visualStyle: IslandVisualStyle

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    public init(
        material: IslandSurfaceMaterial,
        shape: S,
        notchSize: CGSize,
        hasHardwareNotch: Bool,
        artworkTint: RGBAColor? = nil,
        visualStyle: IslandVisualStyle = .lunula
    ) {
        self.material = material
        self.shape = shape
        self.notchSize = notchSize
        self.hasHardwareNotch = hasHardwareNotch
        self.artworkTint = artworkTint
        self.visualStyle = visualStyle
    }

    public var body: some View {
        let allowGlass = material == .liquidGlass && !reduceTransparency && contrast != .increased

        if allowGlass {
            liquidGlassBody
        } else {
            obsidianBody
        }
    }

    private var obsidianBody: some View {
        ZStack(alignment: .top) {
            shape.fill(Palette.obsidian)

            if visualStyle == .boring, let artworkTint, !reduceTransparency, contrast != .increased {
                boringArtworkGlow(tint: artworkTint, opacity: 0.20)
                    .clipShape(shape)
            }

            if hasHardwareNotch, notchSize.width > 0, notchSize.height > 0 {
                hardwareNotchCap
                    .clipShape(shape)
            }

            if contrast == .increased {
                shape.stroke(Palette.hairlineContrast, lineWidth: 1.5)
                    .clipShape(shape)
            }
        }
    }

    private var liquidGlassBody: some View {
        ZStack(alignment: .top) {
            if #available(macOS 26.0, *) {
                shape.fill(Color.black.opacity(0.46))
                    .glassEffect(.regular, in: shape)
            } else {
                shape.fill(Palette.obsidian)
            }

            if visualStyle == .boring, let artworkTint {
                boringArtworkGlow(tint: artworkTint, opacity: 0.20)
                    .clipShape(shape)
            }

            shape.stroke(
                LinearGradient(
                    colors: [
                        .white.opacity(0.28),
                        .white.opacity(0.10),
                        .white.opacity(0.18),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1.2
            )
            .clipShape(shape)

            if hasHardwareNotch, notchSize.width > 0, notchSize.height > 0 {
                hardwareNotchCap
                    .clipShape(shape)
            }
        }
    }

    private func boringArtworkGlow(tint: RGBAColor, opacity: Double) -> some View {
        RadialGradient(
            colors: [
                Palette.color(tint).opacity(opacity),
                Palette.color(tint).opacity(opacity * 0.35),
                .clear,
            ],
            center: .topLeading,
            startRadius: 4,
            endRadius: 240
        )
    }

    private var hardwareNotchCap: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 8,
            bottomTrailingRadius: 8,
            topTrailingRadius: 0,
            style: .continuous
        )
        .fill(Palette.obsidian)
        .frame(width: notchSize.width, height: notchSize.height)
    }
}

extension View {
    /// Applies `IslandShellBackground` behind the receiving view.
    public func islandSurfaceMaterial<S: Shape>(
        _ material: IslandSurfaceMaterial,
        in shape: S,
        notchSize: CGSize,
        hasHardwareNotch: Bool,
        artworkTint: RGBAColor? = nil,
        visualStyle: IslandVisualStyle = .lunula
    ) -> some View {
        background {
            IslandShellBackground(
                material: material,
                shape: shape,
                notchSize: notchSize,
                hasHardwareNotch: hasHardwareNotch,
                artworkTint: artworkTint,
                visualStyle: visualStyle
            )
        }
    }
}
