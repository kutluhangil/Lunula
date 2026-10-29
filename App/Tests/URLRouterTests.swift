import Foundation
import IslandCore
import IslandCoreTestSupport
import Testing

@testable import Lunula

@MainActor @Suite struct URLRouterTests {
    let time = ManualTime()

    func make(toggled: @escaping @MainActor () -> Void = {}) -> (URLRouter, CustomActivityController, TimerController) {
        let custom = CustomActivityController(time: time)
        let timer = TimerController(time: time, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        return (URLRouter(custom: custom, timer: timer, toggle: toggled, time: time), custom, timer)
    }

    @Test func routerDispatchesShowAndTimer() {
        let (r, custom, timer) = make()
        r.handle(URL(string: "lunula://activity/show?id=build&title=Derleme")!)
        r.handle(URL(string: "lunula://timer/start?minutes=5")!)
        #expect(custom.activities.count == 1 && timer.current?.duration == 300)
    }

    @Test func routerDropsCommandsBeyondRateLimit() {
        let (r, custom, _) = make()
        for i in 0..<15 { r.handle(URL(string: "lunula://activity/show?id=a\(i % 3)&title=t")!) }
        #expect(custom.activities.count <= 3)
        #expect(r.handle(URL(string: "lunula://island/toggle")!) == .failure(.rateLimited))
    }

    @Test func invalidURLIsIgnored() {
        let (r, custom, _) = make()
        #expect(
            r.handle(URL(string: "lunula://activity/show?id=a")!) == .failure(.missingParameter("title"))
                && custom.activities.isEmpty)
    }
}
