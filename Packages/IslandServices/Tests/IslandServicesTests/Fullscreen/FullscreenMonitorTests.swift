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

    @Test(.timeLimit(.minutes(1))) func refreshEvaluatesWithoutANotification() async {
        let cover = WindowInfo(
            ownerPID: 42, layer: 0, bounds: CGRect(x: 0, y: 0, width: 1512, height: 982), isOnscreen: true)
        let monitor = FullscreenMonitor(
            workspaceCenter: NotificationCenter(), reader: FakeReader(result: [cover]),
            screens: { [.mbp14] }, frontmostPID: { 42 }, settleDelay: .milliseconds(50))
        var iterator = monitor.updates().makeAsyncIterator()
        monitor.refresh()
        #expect(await iterator.next() == [1: true])
    }

    @Test(.timeLimit(.minutes(1))) func usesPrimaryScreenNotFocusedScreenForQuartzConversion() async {
        let center = NotificationCenter()
        var builtIn = ScreenDescriptor.mbp14
        builtIn.isMain = false
        var external = ScreenDescriptor.external
        external.isMain = true  // focused screen, but not the primary one
        let cover = WindowInfo(
            ownerPID: 42, layer: 0, bounds: CGRect(x: 1512, y: -458, width: 2560, height: 1440), isOnscreen: true)
        let monitor = FullscreenMonitor(
            workspaceCenter: center, reader: FakeReader(result: [cover]),
            screens: { [builtIn, external] }, frontmostPID: { 42 }, settleDelay: .milliseconds(50))
        var iterator = monitor.updates().makeAsyncIterator()
        center.post(name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        let first = await iterator.next()
        #expect(first == [1: false, 2: true])
    }
}
