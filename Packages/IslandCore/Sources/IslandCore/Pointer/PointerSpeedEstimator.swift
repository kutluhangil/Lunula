import Foundation

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// Pointer speed over a short sliding window, used to skip the peek when the cursor only passes through.
public struct PointerSpeedEstimator: Sendable {
    private let window: TimeInterval
    private var samples: [(point: CGPoint, time: TimeInterval)] = []

    public init(window: TimeInterval = 0.05) {
        self.window = window
    }

    public mutating func add(_ p: CGPoint, at t: TimeInterval) {
        samples.append((p, t))
        samples.removeAll { t - $0.time > window }
    }

    /// Points per second between the oldest and newest sample inside the window; fewer than 2 samples → 0.
    public func speed(at t: TimeInterval) -> Double {
        let recent = samples.filter { t - $0.time <= window }
        guard let first = recent.first, let last = recent.last, last.time > first.time else { return 0 }
        let dx = Double(last.point.x - first.point.x)
        let dy = Double(last.point.y - first.point.y)
        return (dx * dx + dy * dy).squareRoot() / (last.time - first.time)
    }
}
