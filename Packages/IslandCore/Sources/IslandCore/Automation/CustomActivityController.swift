import Foundation
import Observation

/// Activities shown from URLs and Shortcuts. One timer at the earliest expiry removes them (no polling).
@MainActor @Observable public final class CustomActivityController: ActivityProviding {
    @ObservationIgnored private let time: IslandTime
    @ObservationIgnored private var registry = CustomActivityRegistry()
    @ObservationIgnored private var expiry: ScheduledToken?
    @ObservationIgnored public var onActivitiesChange: (@MainActor () -> Void)?

    public private(set) var activities: [Activity] = []

    public init(time: IslandTime) { self.time = time }

    public func show(_ request: CustomActivityRequest) {
        _ = registry.upsert(request, now: time.now)
        publish()
    }

    public func end(id: String) {
        guard registry.end(id: id) else { return }
        publish()
    }

    /// Whether an activity with this id is showing (Update intent requires one).
    public func contains(id: String) -> Bool { registry.activities.contains { $0.id.rawValue == id } }

    private func publish() {
        activities = registry.activities
        expiry?.cancel()
        if let next = activities.compactMap(\.expiresAt).min() {
            expiry = time.schedule(after: max(0, next.timeIntervalSince(time.now))) { [weak self] in
                guard let self else { return }
                registry.removeExpired(now: time.now)
                publish()
            }
        }
        onActivitiesChange?()
    }
}
