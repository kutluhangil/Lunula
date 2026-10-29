import AppKit
import Foundation

/// Apple Events (Automation) consent for a target app. Checks never prompt; only `requestConsent`, called after the
/// user taps "Allow", may show the system dialog.
public struct AutomationPermissionChecker: AutomationPermissionChecking {
    /// Opened when access was denied (Settings › Privacy & Security › Automation).
    public static let settingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!

    public init() {}

    public func status(for bundleID: String) async -> AutomationPermission {
        await Task.detached { Self.determine(bundleID, ask: false) }.value
    }

    public func requestConsent(for bundleID: String) async -> AutomationPermission {
        // The consent dialog belongs to the frontmost app; bring Lunula forward first.
        await MainActor.run { NSApp.activate() }
        return await Task.detached { Self.determine(bundleID, ask: true) }.value
    }

    public static func permission(forStatus status: OSStatus) -> AutomationPermission {
        switch status {
        case noErr: .granted
        case -1743: .denied
        case -600: .notRunning
        default: .needsConsent  // -1744 and anything unexpected: ask, never script blindly
        }
    }

    private static func determine(_ bundleID: String, ask: Bool) -> AutomationPermission {
        let target = NSAppleEventDescriptor(bundleIdentifier: bundleID)
        guard let desc = target.aeDesc else { return .needsConsent }
        return permission(
            forStatus: AEDeterminePermissionToAutomateTarget(desc, typeWildCard, typeWildCard, ask))
    }
}
