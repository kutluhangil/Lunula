import SwiftUI

extension EnvironmentValues {
    /// When true, inner cards receive a subtle specular top-edge glass sheen while keeping the island core opaque #000000.
    @Entry public var islandCardGlass: Bool = false
}

extension View {
    /// Card surface inside the expanded island: an opaque fill with a faint top light and a hairline edge,
    /// outlined more strongly under Increase Contrast.
    public func islandCard() -> some View { modifier(IslandCardModifier()) }
}

private struct IslandCardModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.islandCardGlass) private var glass

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
        let showGlass = glass && !reduceTransparency && contrast != .increased
        content
            .background {
                shape.fill(Palette.inkRaised)
                    .overlay {
                        if showGlass {
                            shape.fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.08), .white.opacity(0.015), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom))
                        }
                    }
                    .overlay {
                        if showGlass {
                            shape.strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.24), Palette.hairline],
                                    startPoint: .top,
                                    endPoint: .bottom),
                                lineWidth: 0.75)
                        } else {
                            shape.strokeBorder(
                                contrast == .increased ? .white.opacity(0.35) : Palette.hairline,
                                lineWidth: contrast == .increased ? 1 : 0.5)
                        }
                    }
            }
    }
}
