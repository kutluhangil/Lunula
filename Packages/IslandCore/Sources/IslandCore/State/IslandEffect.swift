import Foundation

public enum IslandTimer: Hashable, Sendable {
    case dwell
    case exitGrace
    case alertExpiry
}

public enum HapticKind: Hashable, Sendable {
    case alignment
    case levelChange
    case generic
}

public enum SoundKind: Hashable, Sendable {
    case timerFinished
}

/// Scheduling a timer of a kind that is already pending replaces the old one (executor contract, T3.4).
public enum IslandEffect: Hashable, Sendable {
    case schedule(IslandTimer, after: TimeInterval)
    case cancel(IslandTimer)
    case playHaptic(HapticKind)
    case playSound(SoundKind)
    case makePanelKey(Bool)
    case setMouseEventsIgnored(Bool)
}

public struct IslandTransition: Equatable, Sendable {
    public var state: IslandState
    public var effects: [IslandEffect]

    public init(state: IslandState, effects: [IslandEffect]) {
        self.state = state
        self.effects = effects
    }
}
