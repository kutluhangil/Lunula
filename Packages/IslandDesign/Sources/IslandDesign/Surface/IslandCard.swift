import SwiftUI

extension View {
    /// Card surface inside the expanded island: an opaque fill with a faint top light and a hairline edge,
    /// outlined more strongly under Increase Contrast.
    public func islandCard() -> some View { modifier(IslandCardModifier()) }
}

private struct IslandCardModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
        content
            .background {
                shape.fill(Palette.inkRaised)
                    .overlay {
                        shape.fill(
                            LinearGradient(
                                colors: [.white.opacity(0.07), .white.opacity(0.015)], startPoint: .top,
                                endPoint: .bottom))
                    }
                    .overlay { shape.strokeBorder(.white.opacity(contrast == .increased ? 0.35 : 0.08), lineWidth: 1) }
            }
    }
}
