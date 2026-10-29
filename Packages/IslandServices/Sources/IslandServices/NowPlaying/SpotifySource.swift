import CryptoKit
import Foundation
import IslandCore

/// Spotify via AppleScript (needs a temporary-exception entitlement; registered only under LUNULA_SPOTIFY).
public final class SpotifySource: NowPlayingSource, @unchecked Sendable {  // `artworkURLs` guarded by `lock`
    public let id: MediaSourceID = .spotify
    public let bundleID = SpotifyScripts.bundleID
    public let notificationName = Notification.Name("com.spotify.client.PlaybackStateChanged")
    private let runner: ScriptRunner
    private let session: URLSession
    private let cacheDirectory: URL
    private let lock = NSLock()
    private var artworkURLs: [String: URL] = [:]

    public init(runner: ScriptRunner, session: URLSession = .shared, cacheDirectory: URL) {
        self.runner = runner
        self.session = session
        self.cacheDirectory = cacheDirectory
    }

    public func snapshot(now: Date) async -> NowPlayingSnapshot? {
        guard case .success(let value) = await runner.run(SpotifyScripts.query, target: bundleID),
            let parsed = SpotifyScriptParser.parse(value, now: now)
        else { return nil }
        if let url = parsed.artworkURL { lock.withLock { artworkURLs[parsed.snapshot.trackID] = url } }
        return parsed.snapshot
    }

    public func artwork(for trackID: String) async -> Data? {
        let name = SHA256.hash(data: Data(trackID.utf8)).map { String(format: "%02x", $0) }.joined()
        let file = cacheDirectory.appendingPathComponent(name + ".jpg")
        if let cached = try? Data(contentsOf: file) { return cached }
        guard let url = lock.withLock({ artworkURLs[trackID] }),
            let (data, response) = try? await session.data(from: url),
            (response as? HTTPURLResponse)?.statusCode == 200
        else { return nil }
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try? data.write(to: file, options: .atomic)
        return data
    }

    public func perform(_ command: PlaybackCommand) async {
        _ = await runner.run(SpotifyScripts.command(command), target: bundleID)
    }
}
