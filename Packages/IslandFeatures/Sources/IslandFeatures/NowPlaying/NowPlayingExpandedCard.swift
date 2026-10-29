import IslandCore
import IslandDesign
import SwiftUI

struct NowPlayingExpandedCard: View {
    let snapshot: NowPlayingSnapshot
    let accent: RGBAColor?
    @Environment(\.nowPlayingActions) private var actions

    init(snapshot: NowPlayingSnapshot, accent: RGBAColor?) {
        self.snapshot = snapshot
        self.accent = accent
    }

    var body: some View {
        HStack(spacing: 12) {
            ArtworkImage(snapshot: snapshot, side: 64, radius: Radii.artworkLarge)
            VStack(alignment: .leading, spacing: 4) {
                MarqueeText(text: snapshot.title, font: TypeToken.title.font).foregroundStyle(Palette.textPrimary)
                Text(snapshot.artist)
                    .font(TypeToken.body.font)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
                NowPlayingProgressBar(snapshot: snapshot, accent: accent)
                HStack(spacing: 18) {
                    control("backward.fill", AccessibilityLabels.previous, actions.previous)
                    control(
                        snapshot.isPlaying ? "pause.fill" : "play.fill",
                        AccessibilityLabels.playPause(isPlaying: snapshot.isPlaying), actions.playPause)
                    control("forward.fill", AccessibilityLabels.next, actions.next)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Palette.inkRaised, in: RoundedRectangle(cornerRadius: Radii.card, style: .continuous))
    }

    private func control(_ symbol: String, _ label: LocalizedStringResource, _ action: @escaping @MainActor () -> Void)
        -> some View
    {
        Button(action: action) {
            Image(systemName: symbol).font(TypeToken.title.font).frame(width: 28, height: 28).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Palette.textPrimary)
        .accessibilityLabel(Text(label))
    }
}
