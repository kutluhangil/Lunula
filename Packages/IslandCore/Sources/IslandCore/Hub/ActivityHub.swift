import Foundation
import Observation

/// Merges feature providers into one island layout. No polling: one timer, set to the earliest priority
/// boundary or expiry, triggers the next recomputation.
@MainActor public final class ActivityHub {
    private let time: IslandTime
    private let settings: SettingsStore
    private var providers: [(provider: ActivityProviding, feature: IslandFeature)] = []
    private var boundary: ScheduledToken?

    public var onLayoutChange: (@MainActor (IslandLayout) -> Void)?
    public var onAlert: (@MainActor (TransientAlert) -> Void)?
    public private(set) var layout: IslandLayout = .empty

    public init(time: IslandTime, settings: SettingsStore) {
        self.time = time
        self.settings = settings
        observeSettings()
    }

    public func register(_ provider: ActivityProviding, feature: IslandFeature) {
        providers.append((provider, feature))
        provider.onActivitiesChange = { [weak self] in self?.refresh() }
        refresh()
    }

    public func register(alerts: AlertProviding, feature: IslandFeature) {
        alerts.onAlert = { [weak self] alert in self?.deliver(alert, feature: feature) }
    }

    public func refresh() {
        let now = time.now
        let enabled = settings.settings.enabledFeatures
        let activities = providers.filter { enabled.contains($0.feature) }
            .flatMap(\.provider.activities)
            .filter { ($0.expiresAt ?? .distantFuture) > now }
            .map { activity -> Activity in
                guard activity.kind != .custom else { return activity }
                var updated = activity
                updated.priority = ActivityPriorityRules.priority(for: activity.content, now: now)
                return updated
            }

        let next = activities.compactMap { activity in
            [ActivityPriorityRules.nextChange(for: activity.content, now: now), activity.expiresAt]
                .compactMap { $0 }.filter { $0 > now }.min()
        }.min()
        boundary?.cancel()
        boundary = next.map { date in
            time.schedule(after: date.timeIntervalSince(now)) { [weak self] in self?.refresh() }
        }

        let updated = ActivityScheduler.layout(for: activities, now: now)
        guard updated != layout else { return }
        layout = updated
        onLayoutChange?(updated)
    }

    private func deliver(_ alert: TransientAlert, feature: IslandFeature) {
        guard settings.settings.enabledFeatures.contains(feature) else { return }
        let muted = (settings.settings.muteUntil ?? .distantPast) > time.now
        if muted && alert.priority < .critical { return }
        onAlert?(alert)
    }

    private func observeSettings() {
        withObservationTracking {
            _ = settings.settings
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.refresh()
                self?.observeSettings()
            }
        }
    }
}
