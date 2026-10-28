import Foundation

public enum IslandPage: Hashable, Sendable {
    case home
    case shelf
    case activity(ActivityID)
}

public enum IslandPhase: Hashable, Sendable {
    case hidden
    case idle
    case compact
    case peek
    case expanded(IslandPage)
    case transient(TransientAlert)

    public var isOpen: Bool {
        switch self {
        case .peek, .expanded: true
        default: false
        }
    }
}

public struct IslandOptions: Equatable, Sendable {
    public var hideInFullscreen = true
    public var criticalAlertsInFullscreen = true

    public init() {}
}

public struct IslandState: Equatable, Sendable {
    public var phase: IslandPhase = .idle
    public var layout: IslandLayout = .empty
    public var isFullscreen = false
    public var pointerInside = false
    public var pendingAlerts: [TransientAlert] = []
    public var options = IslandOptions()

    public init() {}

    /// The phase the island returns to when nothing is open and no alert is pending.
    public var restingPhase: IslandPhase {
        if isFullscreen && options.hideInFullscreen { return .hidden }
        return layout.primary == nil ? .idle : .compact
    }
}
