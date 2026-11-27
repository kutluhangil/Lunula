import IslandCore
import IslandDesign
import SwiftUI

/// The 76 pt animated notch contour header for onboarding with live style and surface material preview.
/// Features a 1.6s stroke trace and a settling style-reactive glow (static under Reduce Motion).
struct OnboardingLightAnimation: View {
    private static let boringTint = RGBAColor(red: 0.92, green: 0.32, blue: 0.62)

    var visualStyle: IslandVisualStyle = .lunula
    var surfaceMaterial: IslandSurfaceMaterial = .obsidian

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var strokeProgress: CGFloat = 0
    @State private var glowSettled = false

    private var gradient: LinearGradient {
        switch visualStyle {
        case .lunula:
            return LinearGradient(
                stops: [
                    .init(color: Palette.amberGold, location: 0.0),
                    .init(color: Palette.warmCream, location: 0.5),
                    .init(color: Palette.amberGold, location: 1.0),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .alcove:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.32),
                    Color.white.opacity(0.55),
                    Color.white.opacity(0.32),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .boring:
            return LinearGradient(
                colors: [
                    Color(red: 0.92, green: 0.32, blue: 0.62),
                    Color(red: 0.62, green: 0.36, blue: 0.94),
                    Color(red: 0.92, green: 0.32, blue: 0.62),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private var effectiveGlowOpacity: Double {
        guard glowSettled else { return 0 }
        switch visualStyle {
        case .lunula: return 0.32
        case .alcove: return 0.0
        case .boring: return 0.30
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            ZStack {
                Color.black

                if surfaceMaterial == .liquidGlass {
                    RadialGradient(
                        colors: [
                            Color(red: 0x2B / 255, green: 0x32 / 255, blue: 0x66 / 255).opacity(0.55),
                            Color.clear,
                        ],
                        center: .top,
                        startRadius: 4,
                        endRadius: 180
                    )
                }
            }

            ZStack {
                if effectiveGlowOpacity > 0 {
                    IslandShape.closed
                        .stroke(gradient, lineWidth: 16)
                        .blur(radius: 7)
                        .opacity(effectiveGlowOpacity)
                        .frame(width: 200, height: 32)
                }

                IslandShellBackground(
                    material: surfaceMaterial,
                    shape: IslandShape.closed,
                    notchSize: CGSize(width: 96, height: 24),
                    hasHardwareNotch: true,
                    artworkTint: Self.boringTint,
                    visualStyle: visualStyle
                )
                .frame(width: 200, height: 32)

                IslandShape.closed
                    .trim(from: 0, to: strokeProgress)
                    .stroke(gradient, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                    .frame(width: 200, height: 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(height: 76)
        .animation(.smooth(duration: 0.25), value: visualStyle)
        .animation(.smooth(duration: 0.25), value: surfaceMaterial)
        .onAppear {
            if reduceMotion {
                strokeProgress = 1.0
                glowSettled = true
            } else {
                withAnimation(.easeInOut(duration: 1.6)) {
                    strokeProgress = 1.0
                }
                withAnimation(.easeOut(duration: 0.4).delay(1.2)) {
                    glowSettled = true
                }
            }
        }
    }
}
