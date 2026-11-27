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
                    colors: liquidGlassEdgeColors,
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

    private var liquidGlassEdgeColors: [Color] {
        if let artworkTint {
            [
                .white.opacity(0.28),
                Palette.color(artworkTint).opacity(0.24),
                .white.opacity(0.18),
            ]
        } else {
            [
                .white.opacity(0.28),
                .white.opacity(0.10),
                .white.opacity(0.18),
            ]
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

    /// Applies secondary popover chrome matching the active island surface material.
    public func islandPopoverChrome(
        _ material: IslandSurfaceMaterial,
        cornerRadius: CGFloat = 14
    ) -> some View {
        modifier(IslandPopoverChromeModifier(material: material, cornerRadius: cornerRadius))
    }
}

/// Circular surface background for detached secondary buds (`BubbleView`).
public struct IslandBubbleBackground: View {
    public var material: IslandSurfaceMaterial

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    public init(material: IslandSurfaceMaterial) {
        self.material = material
    }

    public var body: some View {
        let allowGlass = material == .liquidGlass && !reduceTransparency && contrast != .increased

        if allowGlass {
            ZStack {
                if #available(macOS 26.0, *) {
                    Circle()
                        .fill(Color.black.opacity(0.46))
                        .glassEffect(.regular, in: Circle())
                } else {
                    Circle().fill(Palette.obsidian)
                }
                Circle()
                    .strokeBorder(.white.opacity(0.22), lineWidth: 0.8)
            }
        } else {
            ZStack {
                Circle().fill(Palette.obsidian)
                if contrast == .increased {
                    Circle().strokeBorder(Palette.hairlineContrast, lineWidth: 1.5)
                }
            }
        }
    }
}

private struct IslandPopoverChromeModifier: ViewModifier {
    let material: IslandSurfaceMaterial
    let cornerRadius: CGFloat

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let allowGlass = material == .liquidGlass && !reduceTransparency && contrast != .increased

        content
            .background {
                if allowGlass {
                    if #available(macOS 26.0, *) {
                        shape
                            .fill(Color.black.opacity(0.52))
                            .glassEffect(.regular, in: shape)
                    } else {
                        shape.fill(Palette.obsidian)
                    }
                } else {
                    shape.fill(Palette.obsidian)
                }
            }
            .overlay {
                if allowGlass {
                    shape.strokeBorder(.white.opacity(0.20), lineWidth: 0.8)
                        .allowsHitTesting(false)
                } else {
                    shape.strokeBorder(
                        contrast == .increased ? Palette.hairlineContrast : Palette.hairline,
                        lineWidth: contrast == .increased ? 1.5 : 1.0
                    )
                    .allowsHitTesting(false)
                }
            }
    }
}
