import Foundation
import IslandCore

/// Last snapshot on disk, so the home tile has a value before the first fetch.
public struct WeatherCache: Sendable {
    private let fileURL: URL

    public init(fileURL: URL) { self.fileURL = fileURL }

    public func load() -> WeatherSnapshot? {
        (try? Data(contentsOf: fileURL)).flatMap { try? JSONDecoder().decode(WeatherSnapshot.self, from: $0) }
    }

    public func save(_ snapshot: WeatherSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }

    public static func isFresh(_ snapshot: WeatherSnapshot, now: Date, maxAge: TimeInterval = 1800) -> Bool {
        now.timeIntervalSince(snapshot.fetchedAt) < maxAge
    }
}
