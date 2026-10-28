import AppKit
import Testing

@testable import IslandServices

@MainActor @Suite struct SystemEventsMonitorTests {
    @Test(.timeLimit(.minutes(1))) func mapsWorkspaceNotifications() async {
        let center = NotificationCenter()
        let monitor = SystemEventsMonitor(workspaceCenter: center)
        var iterator = monitor.events().makeAsyncIterator()
        for name in [
            NSWorkspace.willSleepNotification, NSWorkspace.didWakeNotification,
            NSWorkspace.screensDidSleepNotification, NSWorkspace.screensDidWakeNotification,
        ] {
            center.post(name: name, object: nil)
        }
        var got: [SystemEvent] = []
        for _ in 0..<4 { if let e = await iterator.next() { got.append(e) } }
        #expect(got == [.willSleep, .didWake, .screensDidSleep, .screensDidWake])
    }
}
