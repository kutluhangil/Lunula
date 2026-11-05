import IslandCore
import IslandDesign
import SwiftUI

struct NowPlayingExpandedCard: View {
    let snapshot: NowPlayingSnapshot
    let accent: RGBAColor?
    @Environment(\.nowPlayingActions) private var actions
    @Environment(\.quickTools) private var quickTools

    init(snapshot: NowPlayingSnapshot, accent: RGBAColor?) {
        self.snapshot = snapshot
        self.accent = accent
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ArtworkImage(snapshot: snapshot, side: 64, radius: Radii.artworkLarge)
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.title)
                    .font(TypeToken.title.font)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                Text(snapshot.artist)
                    .font(TypeToken.body.font)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
                NowPlayingProgressBar(snapshot: snapshot, accent: accent)
                    .padding(.top, 6)
                if let lyric = quickTools.activeLyricLine(snapshot), !lyric.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "music.mic")
                            .font(.system(size: 10, weight: .medium))
                        Text(lyric)
                            .font(TypeToken.caption.font)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                if snapshot.source == .music {
                    Button(action: actions.toggleFavorite) {
                        Image(systemName: "heart")
                            .font(.system(size: 12, weight: .medium))
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 26, height: 26)
                            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Palette.textSecondary)
                    .accessibilityLabel(Text("nowPlaying.favorite", bundle: .module))
                }
                control("backward.fill", AccessibilityLabels.previous, actions.previous)
                control(
                    snapshot.isPlaying ? "pause.fill" : "play.fill",
                    AccessibilityLabels.playPause(isPlaying: snapshot.isPlaying), actions.playPause)
                control("forward.fill", AccessibilityLabels.next, actions.next)
            }
        }
        .frame(maxWidth: .infinity)
        .contextMenu {
            if snapshot.source == .music {
                Button(action: actions.toggleFavorite) {
                    Text("nowPlaying.favorite", bundle: .module)
                }
            }
            Button(action: actions.toggleShuffle) {
                Text("nowPlaying.shuffle", bundle: .module)
            }
            Button(action: actions.cycleRepeat) {
                Text("nowPlaying.repeat", bundle: .module)
            }
            Menu {
                ForEach([25, 50, 75, 100], id: \.self) { level in
                    Button("\(level)%") {
                        actions.setVolume(level)
                    }
                }
            } label: {
                Text("nowPlaying.appVolume", bundle: .module)
            }
        }
    }

    private func control(_ symbol: String, _ label: LocalizedStringResource, _ action: @escaping @MainActor () -> Void)
        -> some View
    {
        Button(action: action) {
            Image(systemName: symbol)
                .font(TypeToken.title.font)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 32, height: 32)
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(Palette.textPrimary)
        .accessibilityLabel(Text(label))
    }
}
