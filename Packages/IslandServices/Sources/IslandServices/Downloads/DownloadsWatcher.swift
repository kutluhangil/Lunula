import Foundation
import IslandCore

/// "Download finished" alerts from the real ~/Downloads (read-only entitlement): a kqueue write source on the
/// directory, coalesced, then a listing; no polling.
@MainActor public final class DownloadsWatcher: AlertProviding {
    public var onAlert: (@MainActor (TransientAlert) -> Void)?
    private let directory: URL
    private let stabilityDelay: Duration
    private var source: DispatchSourceFileSystemObject?
    private var tracker = DownloadTracker()
    private var scan: Task<Void, Never>?

    public init(
        directory: URL = DownloadsWatcher.realDownloadsDirectory(), stabilityDelay: Duration = .milliseconds(1200)
    ) {
        self.directory = directory
        self.stabilityDelay = stabilityDelay
    }

    /// The sandbox container's Downloads is a symlink; resolve the user's real home.
    public nonisolated static func realDownloadsDirectory() -> URL {
        let home = getpwuid(getuid()).flatMap { String(validatingCString: $0.pointee.pw_dir) } ?? NSHomeDirectory()
        return URL(fileURLWithPath: home).appending(path: "Downloads").resolvingSymlinksInPath()
    }

    public func start() {
        guard source == nil else { return }
        let fd = open(directory.path(), O_EVTONLY)
        guard fd >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: .write, queue: .main)
        source.setEventHandler { [weak self] in MainActor.assumeIsolated { self?.schedule(after: .milliseconds(500)) } }
        source.setCancelHandler { close(fd) }
        // Baseline before watching: files already there are not "new". One listing at start, so it stays synchronous.
        _ = tracker.ingest(Self.list(directory))
        source.resume()
        self.source = source
    }

    public func stop() {
        source?.cancel()
        source = nil
        scan?.cancel()
    }

    private func schedule(after delay: Duration) {
        scan?.cancel()
        scan = Task { [weak self, directory] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            let entries = await Task.detached { Self.list(directory) }.value
            self?.ingest(entries)
        }
    }

    private func ingest(_ entries: Set<FileEntry>) {
        for file in tracker.ingest(entries) {
            onAlert?(
                TransientAlert(
                    id: UUID(), kind: .downloadFinished,
                    detail: .file(name: file.name, url: directory.appending(path: file.name)), tint: .neutral,
                    duration: 2.6, priority: .normal))
        }
        if tracker.hasPending { schedule(after: stabilityDelay) }
    }

    private nonisolated static func list(_ directory: URL) -> Set<FileEntry> {
        let urls =
            (try? FileManager.default.contentsOfDirectory(
                at: directory, includingPropertiesForKeys: [.fileSizeKey, .totalFileSizeKey])) ?? []
        return Set(
            urls.map { url in
                let values = try? url.resourceValues(forKeys: [.fileSizeKey, .totalFileSizeKey])
                return FileEntry(
                    name: url.lastPathComponent, size: Int64(values?.totalFileSize ?? values?.fileSize ?? 0))
            })
    }
}
