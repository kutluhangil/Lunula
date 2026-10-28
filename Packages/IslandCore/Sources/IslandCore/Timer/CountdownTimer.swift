import Foundation

/// Wall-clock countdown: remaining time derives from dates, never from ticks, so sleep causes no drift.
public struct CountdownTimer: Equatable, Sendable, Codable {
    public let id: ActivityID
    public var label: String?
    public let phase: TimerPhase
    public let duration: TimeInterval
    public private(set) var startedAt: Date
    public private(set) var pausedAt: Date?
    public private(set) var pausedTotal: TimeInterval

    public init(id: ActivityID, label: String?, phase: TimerPhase, duration: TimeInterval, startedAt: Date) {
        self.id = id
        self.label = label
        self.phase = phase
        self.duration = duration
        self.startedAt = startedAt
        self.pausedAt = nil
        self.pausedTotal = 0
    }

    public func remaining(at now: Date) -> TimeInterval {
        let currentPause = pausedAt.map { now.timeIntervalSince($0) } ?? 0
        return max(0, duration - (now.timeIntervalSince(startedAt) - pausedTotal - currentPause))
    }

    public func isFinished(at now: Date) -> Bool { remaining(at: now) <= 0 }

    /// `nil` while paused.
    public func endDate() -> Date? {
        pausedAt == nil ? startedAt.addingTimeInterval(duration + pausedTotal) : nil
    }

    public mutating func pause(at now: Date) {
        if pausedAt == nil { pausedAt = now }
    }

    public mutating func resume(at now: Date) {
        guard let pausedAt else { return }
        pausedTotal += now.timeIntervalSince(pausedAt)
        self.pausedAt = nil
    }

    public func snapshot(at now: Date, cycle: Int?, totalCycles: Int?) -> TimerSnapshot {
        TimerSnapshot(
            timerID: id, label: label, phase: phase, duration: duration, endsAt: endDate(),
            pausedRemaining: pausedAt == nil ? nil : remaining(at: now), cycle: cycle, totalCycles: totalCycles)
    }
}
