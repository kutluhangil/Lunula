import Foundation

public enum ActivityScheduler {
    /// Drops expired activities, orders by priority, recency, then id, and splits into primary + detached + overflow.
    public static func layout(for activities: [Activity], now: Date, capacity: Int = 3) -> IslandLayout {
        let sorted = activities.filter { ($0.expiresAt ?? .distantFuture) > now }.sorted {
            if $0.priority != $1.priority { return $0.priority > $1.priority }
            if $0.updatedAt != $1.updatedAt { return $0.updatedAt > $1.updatedAt }
            return $0.id.rawValue < $1.id.rawValue
        }
        let shown = Array(sorted.prefix(max(capacity, 0)))
        return IslandLayout(
            primary: shown.first, detached: Array(shown.dropFirst()), overflowCount: sorted.count - shown.count)
    }
}
