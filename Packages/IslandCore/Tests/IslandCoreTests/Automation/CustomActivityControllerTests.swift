import Foundation
import IslandCoreTestSupport
import Testing

@testable import IslandCore

@MainActor @Suite struct CustomActivityControllerTests {
    let time = ManualTime()

    func req(_ id: String, duration: TimeInterval? = nil) -> CustomActivityRequest {
        .init(id: id, title: id, subtitle: nil, symbol: nil, accent: nil, progress: nil, duration: duration)
    }

    @Test func showAddsCustomActivity() {
        let c = CustomActivityController(time: time)
        c.show(req("a"))
        #expect(c.activities.map(\.id) == ["a"])
    }

    @Test func expiryRemovesActivityAndNotifies() {
        let c = CustomActivityController(time: time)
        var changes = 0
        c.onActivitiesChange = { changes += 1 }
        c.show(req("a", duration: 60))
        time.advance(by: 61)
        #expect(c.activities.isEmpty && changes == 2)
    }

    @Test func endRemoves() {
        let c = CustomActivityController(time: time)
        c.show(req("a"))
        c.end(id: "a")
        #expect(c.activities.isEmpty)
    }
}
