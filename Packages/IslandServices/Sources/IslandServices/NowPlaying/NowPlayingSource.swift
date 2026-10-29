import Foundation
import IslandCore

public enum PlaybackCommand: Equatable, Sendable {
    case playPause, next, previous
    case seek(TimeInterval)
}

public enum AutomationPermission: Equatable, Sendable {
    case granted, needsConsent, denied, notRunning
}

public protocol AutomationPermissionChecking: Sendable {
    func status(for bundleID: String) async -> AutomationPermission
    func requestConsent(for bundleID: String) async -> AutomationPermission
}

public protocol NowPlayingSource: Sendable {
    var id: MediaSourceID { get }
    var bundleID: String { get }
    var notificationName: Notification.Name { get }
    func snapshot(now: Date) async -> NowPlayingSnapshot?
    func artwork(for trackID: String) async -> Data?
    func perform(_ command: PlaybackCommand) async
}

/// Shared AppleScript text for the two scriptable players (same verbs in Music and Spotify).
enum PlayerScripts {
    static func wrap(_ bundleID: String, _ body: String) -> String {
        """
        with timeout of 1 second
          tell application id "\(bundleID)"
            \(body)
          end tell
        end timeout
        """
    }

    static func command(_ command: PlaybackCommand) -> String {
        switch command {
        case .playPause: "playpause"
        case .next: "next track"
        case .previous: "previous track"
        case .seek(let seconds): "set player position to \(String(format: "%g", max(0, seconds)))"
        }
    }

    static func texts(_ value: ScriptValue) -> [ScriptValue]? {
        if case .list(let items) = value { items } else { nil }
    }
}

extension ScriptValue {
    var string: String? { if case .text(let s) = self { s } else { nil } }
    var double: Double? { if case .number(let n) = self { n } else { nil } }
}
