import IslandDesign
import SwiftUI

/// The island appearing at the notch with a soft light (≤ 2 s); static under Reduce Motion.
struct OnboardingLightAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lit = false

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.white.opacity(lit ? 0.18 : 0))
                .frame(width: 240, height: 64)
                .blur(radius: 24)
            IslandShape.closed
                .fill(Palette.obsidian)
                .frame(width: lit ? 200 : 120, height: 32)
                .overlay(IslandShape.closed.stroke(Color.white.opacity(lit ? 0.35 : 0), lineWidth: 1))
        }
        .frame(height: 96)
        .onAppear {
            guard !reduceMotion else {
                lit = true
                return
            }
            withAnimation(MotionToken.animation(.open, reduceMotion: false).delay(0.3)) { lit = true }
        }
    }
}
