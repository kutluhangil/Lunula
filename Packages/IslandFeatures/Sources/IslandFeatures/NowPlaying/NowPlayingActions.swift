import AppKit
import IslandCore
import SwiftUI

/// Playback commands and artwork lookup injected by the App; no-ops by default (previews, tests).
public struct NowPlayingActions {
    public var playPause: @MainActor () -> Void = {}
    public var next: @MainActor () -> Void = {}
    public var previous: @MainActor () -> Void = {}
    public var seek: @MainActor (TimeInterval) -> Void = { _ in }
    public var artwork: @MainActor (String) -> NSImage? = { _ in nil }
    /// Scrubbing ticks (every 10 s boundary).
    public var haptic: @MainActor (HapticKind) -> Void = { _ in }
    /// "Allow" on the permission card: the only path to the system Automation prompt.
    public var requestConsent: @MainActor (MediaSourceID) -> Void = { _ in }

    public init(
        playPause: @escaping @MainActor () -> Void, next: @escaping @MainActor () -> Void,
        previous: @escaping @MainActor () -> Void, seek: @escaping @MainActor (TimeInterval) -> Void,
        artwork: @escaping @MainActor (String) -> NSImage?, haptic: @escaping @MainActor (HapticKind) -> Void,
        requestConsent: @escaping @MainActor (MediaSourceID) -> Void
    ) {
        self.requestConsent = requestConsent
        self.playPause = playPause
        self.next = next
        self.previous = previous
        self.seek = seek
        self.artwork = artwork
        self.haptic = haptic
    }

    init() {}
}

extension EnvironmentValues {
    @Entry public var nowPlayingActions = NowPlayingActions()
}

enum NowPlayingProgress {
    static func fraction(position: TimeInterval, duration: TimeInterval?) -> Double {
        guard let duration, duration > 0 else { return 0 }
        return min(max(position / duration, 0), 1)
    }

    /// Position extrapolated from the last scripted read while playing.
    static func position(_ s: NowPlayingSnapshot, at now: Date) -> TimeInterval {
        s.position + (s.isPlaying ? max(0, now.timeIntervalSince(s.positionTimestamp)) : 0)
    }
}
