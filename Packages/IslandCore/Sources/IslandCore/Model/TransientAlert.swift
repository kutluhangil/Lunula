import Foundation

public enum SignalTint: Hashable, Sendable {
    case accent(RGBAColor)
    case green, orange, red, neutral
}

public enum AlertKind: String, CaseIterable, Sendable {
    case charging, unplugged, batteryLow, batteryFull, downloadFinished, timerFinished, trackChanged
    case permissionNeeded, custom
}

/// No localized text lives in Core; views build strings from `kind` + `detail`.
public enum AlertDetail: Hashable, Sendable {
    case batteryLevel(Int)
    case file(name: String, url: URL)
    case track(title: String, artist: String, artworkKey: String?)
    case timer(label: String?, phase: TimerPhase)
    case permission(MediaSourceID)
    case text(title: String, subtitle: String?, symbol: String?)
}

public struct TransientAlert: Identifiable, Hashable, Sendable {
    public var id: UUID
    public var kind: AlertKind
    public var detail: AlertDetail
    public var tint: SignalTint
    public var duration: TimeInterval
    public var priority: ActivityPriority

    public init(
        id: UUID, kind: AlertKind, detail: AlertDetail, tint: SignalTint, duration: TimeInterval,
        priority: ActivityPriority
    ) {
        self.id = id
        self.kind = kind
        self.detail = detail
        self.tint = tint
        self.duration = duration
        self.priority = priority
    }
}
