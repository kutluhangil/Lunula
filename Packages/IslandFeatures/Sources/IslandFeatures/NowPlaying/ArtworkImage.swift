import IslandCore
import IslandDesign
import SwiftUI

struct ArtworkImage: View {
    let snapshot: NowPlayingSnapshot
    let side: CGFloat
    let radius: CGFloat
    var morphID: String?
    @Environment(\.nowPlayingActions) private var actions
    @Environment(\.islandMorphNamespace) private var morphNamespace

    init(snapshot: NowPlayingSnapshot, side: CGFloat, radius: CGFloat, morphID: String? = nil) {
        self.snapshot = snapshot
        self.side = side
        self.radius = radius
        self.morphID = morphID
    }

    var body: some View {
        if let morphID, let morphNamespace {
            artworkCore
                .matchedGeometryEffect(id: morphID, in: morphNamespace)
        } else {
            artworkCore
        }
    }

    private var artworkCore: some View {
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
        .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Palette.hairline, lineWidth: 0.5)
        }
        .accessibilityHidden(true)
    }
}
