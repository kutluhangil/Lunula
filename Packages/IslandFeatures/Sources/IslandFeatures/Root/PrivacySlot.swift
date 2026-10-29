import SwiftUI

/// Right of the notch: camera/microphone dots while in use (T7.5), otherwise a 6 pt spacer.
struct PrivacySlot: View {
    @Environment(\.privacyInfo) private var privacy

    var body: some View {
        let current = privacy.current()
        if current == .none { Color.clear.frame(width: 6) } else { PrivacyDotView(privacy: current) }
    }
}
