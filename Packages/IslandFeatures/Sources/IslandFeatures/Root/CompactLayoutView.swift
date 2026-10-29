import IslandCore
import SwiftUI

/// Closed island with an activity: content in the wings left and right of the hardware notch.
struct CompactLayoutView: View {
    let activity: Activity
    let notchWidth: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            ActivityContentView(activity: activity, slot: .compactLeading).frame(maxWidth: .infinity)
            Color.clear.frame(width: notchWidth)
            HStack(spacing: 0) {
                ActivityContentView(activity: activity, slot: .compactTrailing).frame(maxWidth: .infinity)
                PrivacySlot()
            }
            .frame(maxWidth: .infinity)
        }
    }
}
