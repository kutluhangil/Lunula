import Foundation

/// Identifies when an active microphone or camera session belongs to a known communication app ("Call Island").
public enum CallActivityDetector {
    public static let knownCallApps: [(bundleID: String, displayName: String)] = [
        ("com.apple.FaceTime", "FaceTime"),
        ("us.zoom.xos", "Zoom"),
        ("com.microsoft.teams2", "Teams"),
        ("com.microsoft.teams", "Teams"),
        ("net.whatsapp.WhatsApp", "WhatsApp"),
        ("com.tinyspeck.slackmacgap", "Slack"),
        ("com.hnc.Discord", "Discord"),
        ("Cisco-Systems.Spark", "Webex"),
    ]

    public static func activeCallApp(privacy: PrivacySnapshot, runningBundleIDs: Set<String>) -> String? {
        guard privacy != .none else { return nil }
        for app in knownCallApps where runningBundleIDs.contains(app.bundleID) {
            return app.displayName
        }
        return nil
    }
}
