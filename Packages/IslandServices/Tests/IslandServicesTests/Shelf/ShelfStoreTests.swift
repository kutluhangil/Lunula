import Foundation
import IslandCore
import IslandCoreTestSupport
import Testing

@testable import IslandServices

@MainActor @Suite struct ShelfStoreTests {
    let time = ManualTime()

    func make(copy: Bool = false, retention: Int? = 7) throws -> (ShelfStore, URL) {
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        settings.update {
            $0.shelfCopiesFiles = copy
            $0.shelfRetentionDays = retention
        }
        return (ShelfStore(directory: dir, bookmarks: PlainBookmarkCoding(), time: time, settings: settings), dir)
    }

    func tempFile(_ name: String = "a.txt") throws -> URL {
        let u = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString)-\(name)")
        try Data("x".utf8).write(to: u)
        return u
    }

    @Test func addingFilePersistsAcrossInstances() throws {
        let (s, dir) = try make()
        try s.add([tempFile()])
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        #expect(
            ShelfStore(directory: dir, bookmarks: PlainBookmarkCoding(), time: time, settings: settings).items.count
                == 1)
    }

    @Test func missingOriginalShowsAsMissing() throws {
        let (s, _) = try make()
        let f = try tempFile()
        try s.add([f])
        try FileManager.default.removeItem(at: f)
        #expect(s.status(of: s.items[0]) == .missing)
    }

    @Test func copyModeSurvivesOriginalDeletion() throws {
        let (s, _) = try make(copy: true)
        let f = try tempFile()
        try s.add([f])
        try FileManager.default.removeItem(at: f)
        guard case .available = s.status(of: s.items[0]) else {
            Issue.record("copy should survive")
            return
        }
    }

    @Test func cleanupRemovesItemsOlderThanRetention() throws {
        let (s, _) = try make(retention: 7)
        try s.add([tempFile()])
        time.advance(by: 8 * 86_400)
        s.cleanUp()
        #expect(s.items.isEmpty)
    }

    @Test func neverRetentionKeepsItems() throws {
        let (s, _) = try make(retention: nil)
        try s.add([tempFile()])
        time.advance(by: 365 * 86_400)
        s.cleanUp()
        #expect(s.items.count == 1)
    }

    @Test func removeDeletesCopiedFile() throws {
        let (s, dir) = try make(copy: true)
        try s.add([tempFile()])
        s.remove(s.items[0].id)
        #expect(
            (try? FileManager.default.contentsOfDirectory(atPath: dir.appending(path: "Files").path()))?.isEmpty ?? true
        )
    }

    @Test func duplicateAddMovesToTop() throws {
        let (s, _) = try make()
        let a = try tempFile("a")
        let b = try tempFile("b")
        try s.add([a])
        try s.add([b])
        try s.add([a])
        #expect(s.items.count == 2 && s.items.first?.displayName.hasSuffix("a") == true)
    }

    @Test func maxItemsDropsOldest() throws {
        let (s, _) = try make()
        for _ in 0..<65 { try s.add([tempFile()]) }
        #expect(s.items.count == 64)
    }
}
