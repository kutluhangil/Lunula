import IslandCore
import IslandDesign
import SwiftUI

/// A detached activity as a notch-height black bubble beside the island.
struct BubbleView: View {
    let activity: Activity
    let side: CGFloat

    var body: some View {
        Circle()
            .fill(Palette.obsidian)
            .frame(width: side, height: side)
            .overlay { ActivityContentView(activity: activity, slot: .compactLeading) }
    }
}
