import IslandCore
import IslandDesign
import SwiftUI

/// A detached activity as a notch-height bubble beside the island.
struct BubbleView: View {
    let activity: Activity
    let side: CGFloat
    @Environment(\.quickTools) private var quickTools

    var body: some View {
        IslandBubbleBackground(material: quickTools.surfaceMaterial())
            .frame(width: side, height: side)
            .overlay { ActivityContentView(activity: activity, slot: .compactLeading) }
    }
}
