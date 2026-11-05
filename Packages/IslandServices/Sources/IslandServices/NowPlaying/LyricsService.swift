import Foundation
import IslandCore
import Observation

/// Fetches time-synced LRC lyrics from LRCLIB (`https://lrclib.net/api/get`) off the main thread and caches per track.
@MainActor @Observable public final class LyricsService {
    private struct Response: Decodable {
        var syncedLyrics: String?
    }

    @ObservationIgnored private let session: URLSession
    @ObservationIgnored private var cache: [String: [SyncedLyricLine]] = [:]
    @ObservationIgnored private var activeTask: Task<Void, Never>?

    public private(set) var currentTrackID: String?
    public private(set) var lines: [SyncedLyricLine] = []

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func update(for snapshot: NowPlayingSnapshot?) {
        guard let snapshot else {
            activeTask?.cancel()
            currentTrackID = nil
            lines = []
            return
        }
        let key = "\(snapshot.title)|\(snapshot.artist)"
        guard key != currentTrackID else { return }
        currentTrackID = key
        if let cached = cache[key] {
            lines = cached
            return
        }
        lines = []
        activeTask?.cancel()
        let title = snapshot.title
        let artist = snapshot.artist
        let session = self.session
        activeTask = Task { [weak self] in
            var components = URLComponents(string: "https://lrclib.net/api/get")
            components?.queryItems = [
                URLQueryItem(name: "track_name", value: title),
                URLQueryItem(name: "artist_name", value: artist),
            ]
            guard let url = components?.url else { return }
            var request = URLRequest(url: url)
            request.timeoutInterval = 6
            request.setValue("Lunula/1.0 (https://github.com/kutluhangul/Lunula)", forHTTPHeaderField: "User-Agent")
            guard let (data, response) = try? await session.data(for: request),
                !Task.isCancelled,
                (response as? HTTPURLResponse)?.statusCode == 200,
                let decoded = try? JSONDecoder().decode(Response.self, from: data),
                let synced = decoded.syncedLyrics
            else { return }
            let parsed = SyncedLyricsParser.parse(synced)
            guard !Task.isCancelled else { return }
            self?.cache[key] = parsed
            if self?.currentTrackID == key {
                self?.lines = parsed
            }
        }
    }
}
