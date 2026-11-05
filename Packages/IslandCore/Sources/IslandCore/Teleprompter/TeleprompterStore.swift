import Foundation
import Observation

/// Persists the user's teleprompter script and words-per-minute scroll speed for eye-aligned reading beneath the webcam.
@MainActor @Observable public final class TeleprompterStore {
    static let scriptKey = "teleprompter.script.v1"
    static let speedKey = "teleprompter.speed.v1"

    @ObservationIgnored private let defaults: UserDefaults
    public var script: String {
        didSet { defaults.set(script, forKey: Self.scriptKey) }
    }
    /// Scroll speed in points per second (10...80).
    public var pointsPerSecond: Double {
        didSet {
            let clamped = min(max(pointsPerSecond, 10), 80)
            if pointsPerSecond != clamped { pointsPerSecond = clamped }
            defaults.set(pointsPerSecond, forKey: Self.speedKey)
        }
    }

    public init(defaults: UserDefaults) {
        self.defaults = defaults
        self.script = defaults.string(forKey: Self.scriptKey) ?? ""
        let savedSpeed = defaults.double(forKey: Self.speedKey)
        self.pointsPerSecond = savedSpeed > 0 ? min(max(savedSpeed, 10), 80) : 24
    }
}
