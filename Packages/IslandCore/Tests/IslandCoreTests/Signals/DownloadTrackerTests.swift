import Foundation
import Testing

@testable import IslandCore

@Suite struct DownloadTrackerTests {
    @Test func existingFilesAtStartAreBaseline() {
        var t = DownloadTracker()
        #expect(t.ingest([.init(name: "old.pdf", size: 10)]).isEmpty)
    }

    @Test func fileReportedOnceWhenSizeStable() {
        var t = DownloadTracker()
        _ = t.ingest([])
        #expect(t.ingest([.init(name: "a.zip", size: 5)]).isEmpty)
        #expect(t.ingest([.init(name: "a.zip", size: 5)]).map(\.name) == ["a.zip"])
        #expect(t.ingest([.init(name: "a.zip", size: 5)]).isEmpty)
    }

    @Test func temporaryAndHiddenFilesIgnored() {
        var t = DownloadTracker()
        _ = t.ingest([])
        let tmp: Set<FileEntry> = [
            .init(name: "a.zip.crdownload", size: 5), .init(name: ".DS_Store", size: 1), .init(name: "b.part", size: 2),
        ]
        _ = t.ingest(tmp)
        #expect(t.ingest(tmp).isEmpty)
    }

    @Test func renamedFromCrdownloadIsReported() {
        var t = DownloadTracker()
        _ = t.ingest([])
        _ = t.ingest([.init(name: "a.zip.crdownload", size: 9)])
        _ = t.ingest([.init(name: "a.zip", size: 9)])
        #expect(t.ingest([.init(name: "a.zip", size: 9)]).map(\.name) == ["a.zip"])
    }
}
