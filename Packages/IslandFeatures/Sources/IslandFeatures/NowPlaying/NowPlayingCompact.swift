import IslandCore
import IslandDesign
import SwiftUI

struct NowPlayingCompactLeading: View {
    let snapshot: NowPlayingSnapshot

    init(snapshot: NowPlayingSnapshot) { self.snapshot = snapshot }

    var body: some View {
        ArtworkImage(snapshot: snapshot, side: 20, radius: Radii.artworkSmall, morphID: "hero-artwork")
    }
}

struct NowPlayingCompactTrailing: View {
    let snapshot: NowPlayingSnapshot
    var accent: RGBAColor?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.quickTools) private var quickTools

    init(snapshot: NowPlayingSnapshot, accent: RGBAColor? = nil) {
        self.snapshot = snapshot
        self.accent = accent
    }

    var body: some View {
        if quickTools.compactWingLyrics(),
            let line = quickTools.activeLyricLine(snapshot),
            !line.isEmpty
        {
            Text(line)
                .font(TypeToken.caption.font)
                .foregroundStyle(accent.map(Palette.color) ?? Palette.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 48, alignment: .trailing)
        } else if quickTools.liveAudioSpectrumEnabled(), !quickTools.audioSpectrumBands().isEmpty {
            AudioSpectrumBarsView(
                levels: quickTools.audioSpectrumBands(),
                isPlaying: snapshot.isPlaying,
                accent: accent,
                barWidth: 2,
                height: 12
            )
        } else {
            Image(systemName: "waveform")
                .font(TypeToken.body.font)
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(
                    .variableColor.iterative, options: .repeating, isActive: snapshot.isPlaying && !reduceMotion
                )
                .foregroundStyle(accent.map(Palette.color) ?? Palette.textPrimary)
                .frame(width: 16, height: 16)
                .accessibilityLabel(
                    Text(snapshot.isPlaying ? "nowPlaying.playing" : "nowPlaying.paused", bundle: .module))
        }
    }
}
