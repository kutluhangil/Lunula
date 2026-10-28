import AppKit
import CoreGraphics
import IslandCore
import IslandCoreTestSupport
import Testing

@testable import IslandServices

private struct FakeReader: WindowListReading {
    var result: [WindowInfo]
    func windows() -> [WindowInfo] { result }
}

@MainActor @Suite struct FullscreenMonitorTests {
    @Test(.timeLimit(.minutes(1))) func reevaluatesOnSpaceChange() async {
        let center = NotificationCenter()
        let cover = WindowInfo(
            ownerPID: 42, layer: 0, bounds: CGRect(x: 0, y: 0, width: 1512, height: 982), isOnscreen: true)
        let monitor = FullscreenMonitor(
            workspaceCenter: center, reader: FakeReader(result: [cover]),
            screens: { [.mbp14] }, frontmostPID: { 42 }, settleDelay: .milliseconds(50))
        var iterator = monitor.updates().makeAsyncIterator()
        center.post(name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        let first = await iterator.next()
        #expect(first == [1: true])
    }
}
