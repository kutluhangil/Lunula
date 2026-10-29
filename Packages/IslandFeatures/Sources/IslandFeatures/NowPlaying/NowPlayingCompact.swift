import IslandCore
import IslandDesign
import SwiftUI

struct NowPlayingCompactLeading: View {
    let snapshot: NowPlayingSnapshot

    init(snapshot: NowPlayingSnapshot) { self.snapshot = snapshot }

    var body: some View { ArtworkImage(snapshot: snapshot, side: 20, radius: Radii.artworkSmall) }
}

struct NowPlayingCompactTrailing: View {
    let snapshot: NowPlayingSnapshot
    var accent: RGBAColor?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(snapshot: NowPlayingSnapshot, accent: RGBAColor? = nil) {
        self.snapshot = snapshot
        self.accent = accent
    }

    var body: some View {
        Image(systemName: "waveform")
            .font(TypeToken.body.font)
            .symbolEffect(.variableColor.iterative, options: .repeating, isActive: snapshot.isPlaying && !reduceMotion)
            .foregroundStyle(accent.map(Palette.color) ?? Palette.textPrimary)
            .accessibilityLabel(Text(snapshot.isPlaying ? "nowPlaying.playing" : "nowPlaying.paused", bundle: .module))
    }
}
