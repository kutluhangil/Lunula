import Foundation

public struct CustomActivityRegistry: Equatable, Sendable {
    public private(set) var activities: [Activity] = []

    public init() {}

    @discardableResult
    public mutating func upsert(_ request: CustomActivityRequest, now: Date) -> Activity {
        let id = ActivityID(request.id)
        let existing = activities.firstIndex { $0.id == id }
        let startedAt = existing.map { activities[$0].startedAt } ?? now
        let lifetime = request.duration ?? CustomActivityLimits.maxLifetime
        let expiresAt = min(
            now.addingTimeInterval(lifetime), startedAt.addingTimeInterval(CustomActivityLimits.maxLifetime))
        let activity = Activity(
            id: id, priority: .normal, startedAt: startedAt, updatedAt: now, expiresAt: expiresAt,
            content: .custom(
                CustomActivitySnapshot(
                    title: request.title, subtitle: request.subtitle, symbol: request.symbol,
                    progress: request.progress, endsAt: expiresAt)),
            accent: request.accent)
        if let existing {
            activities[existing] = activity
        } else {
            if activities.count >= CustomActivityLimits.maxConcurrent,
                let oldest = activities.indices.min(by: { activities[$0].updatedAt < activities[$1].updatedAt })
            {
                activities.remove(at: oldest)
            }
            activities.append(activity)
        }
        return activity
    }

    @discardableResult
    public mutating func end(id: String) -> Bool {
        let before = activities.count
        activities.removeAll { $0.id.rawValue == id }
        return activities.count != before
    }

    public mutating func removeExpired(now: Date) {
        activities.removeAll { ($0.expiresAt ?? .distantFuture) <= now }
    }
}
