import Foundation

public struct FileEntry: Hashable, Sendable {
    public var name: String
    public var size: Int64

    public init(name: String, size: Int64) {
        self.name = name
        self.size = size
    }
}

/// Turns directory listings into "download finished" events: the first listing is the baseline; a new file is
/// reported once, when two consecutive listings show it with the same size. Hidden and partial files are ignored.
public struct DownloadTracker: Sendable {
    public static let temporaryExtensions: Set<String> = [
        "crdownload", "download", "part", "partial", "opdownload", "tmp",
    ]

    private var known: Set<String>?
    private var pending: [String: Int64] = [:]

    public init() {}

    public mutating func ingest(_ entries: Set<FileEntry>) -> [FileEntry] {
        let visible = entries.filter {
            !$0.name.hasPrefix(".")
                && !Self.temporaryExtensions.contains(($0.name as NSString).pathExtension.lowercased())
        }
        guard var known else {
            known = Set(visible.map(\.name))
            return []
        }
        var finished: [FileEntry] = []
        for entry in visible.sorted(by: { $0.name < $1.name }) where !known.contains(entry.name) {
            if pending[entry.name] == entry.size {
                finished.append(entry)
                known.insert(entry.name)
                pending[entry.name] = nil
            } else {
                pending[entry.name] = entry.size
            }
        }
        let names = Set(visible.map(\.name))
        pending = pending.filter { names.contains($0.key) }
        self.known = known.intersection(names).union(finished.map(\.name))
        return finished
    }

    public var hasPending: Bool { !pending.isEmpty }
}
