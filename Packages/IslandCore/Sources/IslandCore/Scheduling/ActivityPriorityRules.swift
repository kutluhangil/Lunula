import Foundation

public enum ActivityPriorityRules {
    public static func priority(for content: ActivityContent, now: Date) -> ActivityPriority {
        switch content {
        case .nowPlaying(let s):
            return s.isPlaying ? .normal : .ambient
        case .timer(let t):
            guard let endsAt = t.endsAt else { return .ambient }
            let remaining = endsAt.timeIntervalSince(now)
            return remaining <= 0 ? .critical : remaining <= 60 ? .high : .normal
        case .calendar(let e):
            let d = e.start.timeIntervalSince(now)
            return (-60 < d && d <= 60) ? .critical : .high
        case .custom:
            return .normal
        }
    }

    public static func nextChange(for content: ActivityContent, now: Date) -> Date? {
        let boundaries: [Date]
        switch content {
        case .timer(let t):
            guard let endsAt = t.endsAt else { return nil }
            boundaries = [endsAt.addingTimeInterval(-60), endsAt]
        case .calendar(let e):
            boundaries = [-60, 60, 300].map { e.start.addingTimeInterval($0) }
        case .nowPlaying, .custom:
            return nil
        }
        return boundaries.first { $0 > now }
    }
}
