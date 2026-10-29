import Foundation

/// Every control label in one place (spec §6.5, T9.4); views use `Text(AccessibilityLabels.…)`.
public enum AccessibilityLabels {
    private static let bundle = LocalizedStringResource.BundleDescription.atURL(Bundle.module.bundleURL)

    public static func playPause(isPlaying: Bool) -> LocalizedStringResource {
        isPlaying
            ? LocalizedStringResource("a11y.pause", bundle: bundle)
            : LocalizedStringResource("a11y.play", bundle: bundle)
    }

    public static let next = LocalizedStringResource("a11y.next", bundle: bundle)
    public static let previous = LocalizedStringResource("a11y.previous", bundle: bundle)
    public static let seek = LocalizedStringResource("a11y.seek", bundle: bundle)
    public static let startTimer = LocalizedStringResource("a11y.startTimer", bundle: bundle)
    public static let pauseTimer = LocalizedStringResource("a11y.pauseTimer", bundle: bundle)
    public static let join = LocalizedStringResource("a11y.join", bundle: bundle)
    public static let removeShelfItem = LocalizedStringResource("a11y.removeShelfItem", bundle: bundle)
    public static let openSettings = LocalizedStringResource("a11y.openSettings", bundle: bundle)

    public static func island(summary: String) -> LocalizedStringResource {
        LocalizedStringResource("a11y.island \(summary)", bundle: bundle)
    }
}
