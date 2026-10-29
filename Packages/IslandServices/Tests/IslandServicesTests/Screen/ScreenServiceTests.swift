import AppKit
import IslandCore
import IslandCoreTestSupport
import Testing

@testable import IslandServices

@MainActor @Suite struct ScreenServiceTests {
    func collect(_ s: ScreenService, for ms: Int) async -> [[ScreenDescriptor]] {
        var out: [[ScreenDescriptor]] = []
        // Subscribe before the first await so a notification posted right after cannot be missed.
        let stream = s.updates()
        let task = Task { for await v in stream { out.append(v) } }
        try? await Task.sleep(for: .milliseconds(ms))
        task.cancel()
        return out
    }
    @Test func descriptorChangeIsDebounced() async {  // Review Focus #1
        let c = NotificationCenter()
        let w = NotificationCenter()
        let s = ScreenService(center: c, workspaceCenter: w, debounce: .milliseconds(150), provider: { [.mbp14] })
        Task {
            for _ in 0..<3 {
                c.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)
                try? await Task.sleep(for: .milliseconds(10))
            }
        }
        #expect(await collect(s, for: 1000).count == 1)
    }
    @Test func geometryRecomputedOnScreenChange() async {  // Review Focus #1
        let c = NotificationCenter()
        let screens = ScreenBox([.mbp14])
        let s = ScreenService(
            center: c, workspaceCenter: NotificationCenter(), debounce: .milliseconds(20), provider: { screens.value })
        screens.value = [.mbp14, .external]
        Task { c.post(name: NSApplication.didChangeScreenParametersNotification, object: nil) }
        #expect(await collect(s, for: 1000).last?.count == 2)
    }
    @Test func wakeTriggersRecompute() async {
        let w = NotificationCenter()
        let s = ScreenService(
            center: NotificationCenter(), workspaceCenter: w, debounce: .milliseconds(20), provider: { [.mbp14] })
        Task { w.post(name: NSWorkspace.didWakeNotification, object: nil) }
        #expect(await collect(s, for: 1000).count == 1)
    }
    @Test func updatesAfterStopFinishesImmediately() async {
        let s = ScreenService(
            center: NotificationCenter(), workspaceCenter: NotificationCenter(), provider: { [.mbp14] })
        s.stop()
        var count = 0
        for await _ in s.updates() { count += 1 }
        #expect(count == 0)
    }
    @Test(.enabled(if: !NSScreen.screens.isEmpty)) func liveScreensMapsEveryScreen() {
        #expect(ScreenService.liveScreens().count == NSScreen.screens.count)
    }
}

@MainActor private final class ScreenBox {
    var value: [ScreenDescriptor]
    init(_ value: [ScreenDescriptor]) { self.value = value }
}
