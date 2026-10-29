import Foundation
import IslandCore
import Testing

@testable import IslandServices

@MainActor @Suite struct DownloadsWatcherTests {
    @Test func realDownloadsPathIsNotInsideContainer() {
        #expect(!DownloadsWatcher.realDownloadsDirectory().path().contains("/Library/Containers/"))
    }

    @Test func watcherAlertsForNewFile() async throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let w = DownloadsWatcher(directory: dir, stabilityDelay: .milliseconds(200))
        var names: [String] = []
        w.onAlert = { if case .file(let n, _) = $0.detail { names.append(n) } }
        w.start()
        try Data(count: 100).write(to: dir.appending(path: "rapor.pdf"))
        try await Task.sleep(for: .seconds(2))
        #expect(names == ["rapor.pdf"])
        w.stop()
    }
}
