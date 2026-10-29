import Foundation
import IslandCore
import Observation

/// Files parked on the island's shelf: references by default (security-scoped bookmarks), copies when the user
/// prefers. Persisted in `<directory>/items.json`; copies live in `<directory>/Files/<uuid>/<name>`.
@MainActor @Observable public final class ShelfStore {
    @ObservationIgnored private let directory: URL
    @ObservationIgnored private let bookmarks: BookmarkCoding
    @ObservationIgnored private let time: IslandTime
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private var dailyCleanup: ScheduledToken?

    public private(set) var items: [ShelfItem] = []

    public init(directory: URL, bookmarks: BookmarkCoding, time: IslandTime, settings: SettingsStore) {
        self.directory = directory
        self.bookmarks = bookmarks
        self.time = time
        self.settings = settings
        if let data = try? Data(contentsOf: itemsFile) {
            items = (try? JSONDecoder().decode([ShelfItem].self, from: data)) ?? []
        }
    }

    private var itemsFile: URL { directory.appending(path: "items.json") }
    private var filesDirectory: URL { directory.appending(path: "Files") }

    // shortcut: copies run on the main actor (the interface is synchronous); move large copies off-main if
    // profiling (T9.5) shows hitches.
    public func add(_ urls: [URL]) throws {
        let copies = settings.settings.shelfCopiesFiles
        for url in urls {
            let path = url.standardizedFileURL.path()
            if let existing = items.firstIndex(where: { $0.sourcePath == path || resolvedPath($0) == path }) {
                var item = items.remove(at: existing)
                item.addedAt = time.now
                items.insert(item, at: 0)
                continue
            }
            let id = UUID()
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize.map(Int64.init)
            let storage: ShelfStorage
            if copies {
                let relative = "\(id.uuidString)/\(url.lastPathComponent)"
                let target = filesDirectory.appending(path: relative)
                try FileManager.default.createDirectory(
                    at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: url, to: target)
                storage = .copy(relativePath: relative)
            } else {
                storage = .reference(bookmark: try bookmarks.bookmark(for: url))
            }
            items.insert(
                ShelfItem(
                    id: id, displayName: url.lastPathComponent, addedAt: time.now, storage: storage, byteCount: size,
                    sourcePath: path),
                at: 0)
        }
        while items.count > ShelfLimits.maxItems { deleteFiles(of: items.removeLast()) }
        persist()
    }

    public func remove(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        deleteFiles(of: items.remove(at: index))
        persist()
    }

    public func status(of item: ShelfItem) -> ShelfItemStatus {
        switch item.storage {
        case .copy(let relative):
            let url = filesDirectory.appending(path: relative)
            return FileManager.default.fileExists(atPath: url.path()) ? .available(url) : .missing
        case .reference(let data):
            guard let resolved = resolve(item, data) else { return .missing }
            let exists = withScope(resolved) { FileManager.default.fileExists(atPath: $0.path()) }
            return exists ? .available(resolved) : .missing
        }
    }

    /// Runs `body` with the file reachable: security scope started and always stopped for references.
    public func withAccess<T>(to item: ShelfItem, _ body: (URL) throws -> T) rethrows -> T? {
        guard case .available(let url) = status(of: item) else { return nil }
        if case .copy = item.storage { return try body(url) }
        return try withScope(url, body)
    }

    /// Drops items older than the retention setting (nil = keep forever); runs at launch and once a day.
    public func cleanUp() {
        defer { scheduleDailyCleanup() }
        guard let days = settings.settings.shelfRetentionDays else { return }
        let cutoff = time.now.addingTimeInterval(-Double(days) * 86_400)
        let (old, kept) = (items.filter { $0.addedAt < cutoff }, items.filter { $0.addedAt >= cutoff })
        guard !old.isEmpty else { return }
        old.forEach(deleteFiles)
        items = kept
        persist()
    }

    // MARK: - Private

    private func scheduleDailyCleanup() {
        dailyCleanup?.cancel()
        dailyCleanup = time.schedule(after: 86_400) { [weak self] in self?.cleanUp() }
    }

    private func resolvedPath(_ item: ShelfItem) -> String? {
        guard case .reference(let data) = item.storage else { return nil }
        return resolve(item, data)?.standardizedFileURL.path()
    }

    /// Resolves a reference; a stale bookmark is refreshed and saved.
    private func resolve(_ item: ShelfItem, _ data: Data) -> URL? {
        guard let (url, stale) = try? bookmarks.resolve(data) else { return nil }
        if stale, let fresh = withScope(url, { try? bookmarks.bookmark(for: $0) }),
            let index = items.firstIndex(where: { $0.id == item.id })
        {
            items[index].storage = .reference(bookmark: fresh)
            persist()
        }
        return url
    }

    private func withScope<T>(_ url: URL, _ body: (URL) throws -> T) rethrows -> T {
        let started = url.startAccessingSecurityScopedResource()
        defer { if started { url.stopAccessingSecurityScopedResource() } }
        return try body(url)
    }

    private func deleteFiles(of item: ShelfItem) {
        guard case .copy(let relative) = item.storage else { return }
        try? FileManager.default.removeItem(at: filesDirectory.appending(path: relative).deletingLastPathComponent())
    }

    private func persist() {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try JSONEncoder().encode(items).write(to: itemsFile, options: .atomic)
        } catch {
            assertionFailure("Shelf could not be saved: \(error)")
        }
    }
}
