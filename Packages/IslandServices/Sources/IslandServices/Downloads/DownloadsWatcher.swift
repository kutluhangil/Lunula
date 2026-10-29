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
    private var opening: Task<Void, Never>?

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

    /// Opening the real ~/Downloads can block on a privacy (TCC) check, so it happens off the main thread; call
    /// only after the user turned download alerts on (never at launch).
    public func start() {
        guard source == nil, opening == nil else { return }
        let directory = directory
        opening = Task { [weak self] in
            let opened = await Task.detached { () -> (Int32, Set<FileEntry>)? in
                let fd = open(directory.path(), O_EVTONLY)
                return fd >= 0 ? (fd, Self.list(directory)) : nil
            }.value
            self?.opening = nil
            guard let self, let (fd, baseline) = opened else { return }
            // Baseline before watching: files already there are not "new".
            _ = tracker.ingest(baseline)
            let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: .write, queue: .main)
            source.setEventHandler { [weak self] in
                MainActor.assumeIsolated { self?.schedule(after: .milliseconds(500)) }
            }
            source.setCancelHandler { close(fd) }
            source.resume()
            self.source = source
        }
    }

    public func stop() {
        opening?.cancel()
        opening = nil
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
