import Foundation

/// Sliding window; only allowed calls count toward the limit.
public struct RateLimiter: Sendable {
    private let limit: Int
    private let window: TimeInterval
    private var allowedAt: [Date] = []

    public init(limit: Int = 10, window: TimeInterval = 10) {
        self.limit = limit
        self.window = window
    }

    public mutating func allow(at: Date) -> Bool {
        allowedAt.removeAll { at.timeIntervalSince($0) >= window }
        guard allowedAt.count < limit else { return false }
        allowedAt.append(at)
        return true
    }
}
