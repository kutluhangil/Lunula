import IslandCore
import SwiftUI

/// Hover preview: the primary activity's expanded row under the notch band; empty while only inviting.
struct PeekView: View {
    let layout: IslandLayout
    let notchHeight: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: notchHeight)
            if let primary = layout.primary {
                ActivityContentView(activity: primary, slot: .expanded).frame(maxHeight: .infinity)
            }
        }
    }
}
