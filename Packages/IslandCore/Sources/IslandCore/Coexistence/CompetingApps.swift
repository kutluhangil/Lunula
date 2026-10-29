import Foundation

/// Other notch apps draw in the same place (spec §4.5); Lunula mentions each one once, politely.
public enum CompetingApps {
    // shortcut: IDs other than Sapphire's (verified on 2026-10-29 with mdls) are best known values; verify in T9.6.
    public static let bundleIDs: Set<String> = [
        "theboringteam.boringnotch", "lo.cafe.NotchNook", "com.tonymacaroni.alcove", "com.ebullioscopic.Atoll",
        "com.lakr233.NotchDrop", "com.monuk7735.mew-notch", "com.mrkai77.DynamicNotch", "com.cshariq.sapphire",
        "com.tweety.MediaMate",
    ]

    public static func detect(running: [String], alreadyNotified: Set<String>) -> String? {
        running.first { bundleIDs.contains($0) && !alreadyNotified.contains($0) }
    }
}
