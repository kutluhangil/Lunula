import IslandCore
import IslandDesign
import SwiftUI

enum PrivacyDotColors {
    /// macOS convention: green camera, orange microphone.
    static func colors(for privacy: PrivacySnapshot) -> [Color] {
        (privacy.cameraInUse ? [Palette.signalGreen] : []) + (privacy.microphoneInUse ? [Palette.signalOrange] : [])
    }
}

struct PrivacyDotView: View {
    let privacy: PrivacySnapshot

    init(privacy: PrivacySnapshot) { self.privacy = privacy }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(PrivacyDotColors.colors(for: privacy).enumerated()), id: \.offset) { _, color in
                Circle().fill(color).frame(width: 6, height: 6)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(privacy.cameraInUse ? "privacy.camera" : "privacy.microphone", bundle: .module))
        .accessibilityHidden(privacy == .none)
    }
}

/// Live privacy state, read in the slot's body so Observation re-renders it.
public struct PrivacyInfo {
    public var current: @MainActor () -> PrivacySnapshot = { .none }
    public init(current: @escaping @MainActor () -> PrivacySnapshot) { self.current = current }
    init() {}
}

extension EnvironmentValues {
    @Entry public var privacyInfo = PrivacyInfo()
}
