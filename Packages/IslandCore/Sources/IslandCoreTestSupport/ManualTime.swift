import Foundation
import IslandCore

@MainActor
public final class ManualTime: IslandTime {
    private struct Entry {
        let deadline: Date
        let seq: Int
        let token: ScheduledToken
        let action: @MainActor () -> Void
    }

    public private(set) var now: Date
    private var entries: [Entry] = []
    private var nextSeq = 0

    public init(start: Date = Date(timeIntervalSinceReferenceDate: 800_000_000)) { now = start }

    @discardableResult
    public func schedule(after delay: TimeInterval, _ action: @escaping @MainActor () -> Void) -> ScheduledToken {
        let seq = nextSeq
        nextSeq += 1
        let token = ScheduledToken { [weak self] in self?.entries.removeAll { $0.seq == seq } }
        entries.append(Entry(deadline: now.addingTimeInterval(delay), seq: seq, token: token, action: action))
        return token
    }

    /// Runs every action due by `now + seconds` in deadline order (ties by scheduling order),
    /// including actions scheduled while advancing.
    public func advance(by seconds: TimeInterval) {
        let target = now.addingTimeInterval(seconds)
        while let next = entries.filter({ $0.deadline <= target }).min(by: {
            ($0.deadline, $0.seq) < ($1.deadline, $1.seq)
        }) {
            entries.removeAll { $0.seq == next.seq }
            now = max(now, next.deadline)
            next.action()
        }
        now = target
    }
}
