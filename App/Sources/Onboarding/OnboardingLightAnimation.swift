import IslandDesign
import SwiftUI

/// The 112 pt animated notch contour header for onboarding matching Claude Design Artboard 3.
/// Features the decorative window dots, the black notch shape, 1.6s stroke trace,
/// and a settling amber-cream glow (settles to 0.32 opacity); static under Reduce Motion.
struct OnboardingLightAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var strokeProgress: CGFloat = 0
    @State private var glowOpacity: Double = 0

    private var gradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Palette.amberGold, location: 0.0),
                .init(color: Palette.warmCream, location: 0.5),
                .init(color: Palette.amberGold, location: 1.0),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            Color.black

            // Centered animated notch contour
            VStack {
                ZStack {
                    // Settling glow blur
                    IslandShape.closed
                        .stroke(gradient, lineWidth: 16)
                        .blur(radius: 7)
                        .opacity(glowOpacity)
                        .frame(width: 200, height: 32)

                    // Black notch body
                    IslandShape.closed
                        .fill(Color.black)
                        .frame(width: 200, height: 32)

                    // Crisp animated rim trace
                    IslandShape.closed
                        .trim(from: 0, to: strokeProgress)
                        .stroke(gradient, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                        .frame(width: 200, height: 32)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(height: 112)
        .onAppear {
            if reduceMotion {
                strokeProgress = 1.0
                glowOpacity = 0.32
            } else {
                withAnimation(.easeInOut(duration: 1.6)) {
                    strokeProgress = 1.0
                }
                withAnimation(.easeOut(duration: 0.4).delay(1.2)) {
                    glowOpacity = 0.32
                }
            }
        }
    }
}
