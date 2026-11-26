import IslandCore
import IslandDesign
import SwiftUI

enum NowPlayingVolume {
    static func level(for fraction: Double) -> Int {
        Int((min(max(fraction, 0), 1) * 100).rounded())
    }

    static func symbol(for level: Int) -> String {
        switch level {
        case ...0: "speaker.slash.fill"
        case 1...33: "speaker.wave.1.fill"
        case 34...66: "speaker.wave.2.fill"
        default: "speaker.wave.3.fill"
        }
    }
}

/// Compact drag-to-adjust player volume bar for Apple Music / Spotify (does not touch macOS system HUD).
struct NowPlayingVolumeSlider: View {
    let volume: Int
    let accent: RGBAColor?
    @Environment(\.nowPlayingActions) private var actions
    @State private var dragLevel: Int?
    @State private var lastNonZero = 50
    @State private var lastTick: Int?

    private var displayedLevel: Int { min(max(dragLevel ?? volume, 0), 100) }

    var body: some View {
        HStack(spacing: 6) {
            Button(action: toggleMute) {
                Image(systemName: NowPlayingVolume.symbol(for: displayedLevel))
                    .font(.system(size: 11, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(displayedLevel == 0 ? Palette.textSecondary : Palette.textPrimary)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("nowPlaying.appVolume", bundle: .module))

            GeometryReader { proxy in
                let fraction = Double(displayedLevel) / 100
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.inkPressed)
                    Capsule().fill(accent.map(Palette.color) ?? Palette.textPrimary)
                        .frame(width: proxy.size.width * fraction)
                }
                .frame(height: 4)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in drag(to: value.location.x / max(proxy.size.width, 1)) }
                        .onEnded { _ in commit() })
            }
            .frame(width: 72, height: 14)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("nowPlaying.appVolume", bundle: .module))
        .accessibilityValue(Text("\(displayedLevel)%"))
        .accessibilityAdjustableAction { direction in
            let delta = direction == .increment ? 10 : -10
            let next = min(max(displayedLevel + delta, 0), 100)
            if next > 0 { lastNonZero = next }
            actions.setVolume(next)
        }
        .onChange(of: volume) { _, newValue in
            if newValue > 0 { lastNonZero = newValue }
        }
    }

    private func toggleMute() {
        if displayedLevel > 0 {
            lastNonZero = displayedLevel
            actions.setVolume(0)
        } else {
            actions.setVolume(max(lastNonZero, 25))
        }
        actions.haptic(.generic)
    }

    private func drag(to fraction: Double) {
        let level = NowPlayingVolume.level(for: fraction)
        dragLevel = level
        let tick = level / 10
        if tick != lastTick, lastTick != nil { actions.haptic(.generic) }
        lastTick = tick
    }

    private func commit() {
        if let dragLevel {
            if dragLevel > 0 { lastNonZero = dragLevel }
            actions.setVolume(dragLevel)
        }
        dragLevel = nil
        lastTick = nil
    }
}
