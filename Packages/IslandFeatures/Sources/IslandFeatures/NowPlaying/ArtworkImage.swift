import IslandCore
import IslandDesign
import SwiftUI

struct ArtworkImage: View {
    let snapshot: NowPlayingSnapshot
    let side: CGFloat
    let radius: CGFloat
    @Environment(\.nowPlayingActions) private var actions

    var body: some View {
        Group {
            if let key = snapshot.artworkKey, let image = actions.artwork(key) {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: side * 0.5, weight: .medium))
                    .foregroundStyle(Palette.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Palette.inkPressed)
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .accessibilityHidden(true)
    }
}
