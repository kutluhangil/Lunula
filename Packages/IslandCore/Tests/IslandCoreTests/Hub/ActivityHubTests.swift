import Foundation
import IslandCoreTestSupport
import Testing

@testable import IslandCore

@MainActor final class FakeProvider: ActivityProviding {
    var onActivitiesChange: (@MainActor () -> Void)?
    var activities: [Activity] = [] { didSet { onActivitiesChange?() } }
}

@MainActor final class FakeAlerts: AlertProviding {
    var onAlert: (@MainActor (TransientAlert) -> Void)?
    func emit(_ alert: TransientAlert) { onAlert?(alert) }
}

@MainActor @Suite struct ActivityHubTests {
    let time = ManualTime()

    func makeHub() -> (ActivityHub, SettingsStore) {
        let s = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        return (ActivityHub(time: time, settings: s), s)
    }

    func runningTimer(endsIn s: TimeInterval) -> Activity {
        .fixture(
            id: "timer",
            content: .timer(
                .init(
                    timerID: "timer", label: nil, phase: .simple, duration: 1500,
                    endsAt: time.now.addingTimeInterval(s), pausedRemaining: nil, cycle: nil, totalCycles: nil)))
    }

    @Test func hubMergesProvidersIntoLayout() {
        let (hub, _) = makeHub()
        let a = FakeProvider()
        let b = FakeProvider()
        hub.register(a, feature: .nowPlaying)
        hub.register(b, feature: .timer)
        a.activities = [.fixture(id: "music", content: .nowPlaying(.fixture(isPlaying: true)))]
        b.activities = [runningTimer(endsIn: 600)]
        #expect(hub.layout.primary != nil && hub.layout.detached.count == 1)
    }

    @Test func disabledFeatureIsIgnored() {
        let (hub, settings) = makeHub()
        let p = FakeProvider()
        hub.register(p, feature: .timer)
        settings.update { $0.enabledFeatures.remove(.timer) }
        p.activities = [runningTimer(endsIn: 600)]
        #expect(hub.layout == .empty)
    }

    @Test func hubRecomputesAtPriorityBoundary() {
        let (hub, _) = makeHub()
        let p = FakeProvider()
        hub.register(p, feature: .timer)
        p.activities = [runningTimer(endsIn: 120)]
        #expect(hub.layout.primary?.priority == .normal)
        time.advance(by: 60)
        #expect(hub.layout.primary?.priority == .high)
    }

    @Test func expiredActivityRemovedAtExpiry() {
        let (hub, _) = makeHub()
        let p = FakeProvider()
        hub.register(p, feature: .customActivities)
        p.activities = [.fixture(id: "c", expiresAt: time.now.addingTimeInterval(30))]
        time.advance(by: 31)
        #expect(hub.layout == .empty)
    }

    @Test func unchangedLayoutIsNotReemitted() {
        let (hub, _) = makeHub()
        let p = FakeProvider()
        var count = 0
        hub.onLayoutChange = { _ in count += 1 }
        hub.register(p, feature: .timer)
        p.activities = [runningTimer(endsIn: 600)]
        hub.refresh()
        hub.refresh()
        #expect(count == 1)
    }

    @Test func muteSuppressesNonCriticalAlerts() {
        let (hub, settings) = makeHub()
        let src = FakeAlerts()
        var got: [TransientAlert] = []
        hub.onAlert = { got.append($0) }
        hub.register(alerts: src, feature: .battery)
        settings.update { $0.muteUntil = time.now.addingTimeInterval(3600) }
        src.emit(.fixture(priority: .normal))
        src.emit(.fixture(priority: .critical))
        #expect(got.map(\.priority) == [.critical])
    }
}
