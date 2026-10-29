import IslandCore
import IslandDesign
import SwiftUI

/// Progress with drag-to-seek. Ticks once a second only while visible (it lives in the expanded card).
struct NowPlayingProgressBar: View {
    let snapshot: NowPlayingSnapshot
    let accent: RGBAColor?
    @Environment(\.nowPlayingActions) private var actions
    @State private var dragFraction: Double?
    @State private var lastTick: Int?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let live = NowPlayingProgress.fraction(
                position: NowPlayingProgress.position(snapshot, at: context.date), duration: snapshot.duration)
            let fraction = dragFraction ?? live
            GeometryReader { proxy in
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
            .frame(height: 16)
        }
        .accessibilityElement()
        .accessibilityLabel(Text("nowPlaying.position", bundle: .module))
        .accessibilityValue(
            Text("\(Int(NowPlayingProgress.fraction(position: snapshot.position, duration: snapshot.duration) * 100))%")
        )
    }

    private func drag(to fraction: Double) {
        let clamped = min(max(fraction, 0), 1)
        dragFraction = clamped
        guard let duration = snapshot.duration else { return }
        let tick = Int(clamped * duration / 10)
        if tick != lastTick, lastTick != nil { actions.haptic(.generic) }
        lastTick = tick
    }

    private func commit() {
        if let dragFraction, let duration = snapshot.duration { actions.seek(dragFraction * duration) }
        dragFraction = nil
        lastTick = nil
    }
}
