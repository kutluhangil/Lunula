import Foundation

/// Detects a clean double-tap of a single modifier key (e.g. Option ⌥) within a time window ("Knock to Control"
/// double-tap-a-key mode). Any other modifier combination resets the state so typing shortcuts never false-fire.
public struct ModifierDoubleTapDetector: Sendable {
    public var minimumInterval: TimeInterval
    public var maximumInterval: TimeInterval
    private var isTargetDown = false
    private var lastReleaseTime: Date?
    private var contaminated = false

    public init(minimumInterval: TimeInterval = 0.04, maximumInterval: TimeInterval = 0.36) {
        self.minimumInterval = minimumInterval
        self.maximumInterval = maximumInterval
    }

    /// Call on every `.flagsChanged` event.
    /// - Parameters:
    ///   - targetPressed: true when the target modifier (e.g. `.option`) is currently pressed.
    ///   - otherModifiersPressed: true when any other modifier (`.command`, `.control`, `.shift`) is pressed.
    ///   - now: timestamp of the event.
    /// - Returns: `true` when a clean second tap release completes within the window.
    public mutating func registerFlagsChange(
        targetPressed: Bool, otherModifiersPressed: Bool, at now: Date
    ) -> Bool {
        if otherModifiersPressed {
            isTargetDown = false
            lastReleaseTime = nil
            contaminated = true
            return false
        }
        if targetPressed {
            if !isTargetDown {
                isTargetDown = true
                contaminated = false
            }
            return false
        } else {
            guard isTargetDown, !contaminated else {
                isTargetDown = false
                return false
            }
            isTargetDown = false
            if let previous = lastReleaseTime {
                let delta = now.timeIntervalSince(previous)
                if delta >= minimumInterval && delta <= maximumInterval {
                    lastReleaseTime = nil
                    return true
                }
            }
            lastReleaseTime = now
            return false
        }
    }

    /// Call when a regular key is pressed while modifiers are being used so `⌥ + key` never counts as a tap.
    public mutating func reset() {
        isTargetDown = false
        lastReleaseTime = nil
        contaminated = true
    }
}
