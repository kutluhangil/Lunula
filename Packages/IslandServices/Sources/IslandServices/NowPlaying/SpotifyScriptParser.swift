import Foundation
import IslandCore

enum SpotifyScriptParser {
    /// Spotify reports `duration` in milliseconds (its sdef says seconds). Ads (`spotify:ad:`) and blank names → nil.
    static func parse(_ value: ScriptValue, now: Date) -> (snapshot: NowPlayingSnapshot, artworkURL: URL?)? {
        guard let items = PlayerScripts.texts(value), items.count >= 8, let state = items[0].string,
            state != "stopped", let title = items[1].string, !title.isEmpty, let id = items[6].string,
            !id.hasPrefix("spotify:ad:")
        else { return nil }
        let art = items[7].string.flatMap(URL.init(string:)).flatMap { $0.scheme == "https" ? $0 : nil }
        let snapshot = NowPlayingSnapshot(
            source: .spotify, trackID: id, title: title, artist: items[2].string ?? "", album: items[3].string,
            artworkKey: "spotify:" + id, duration: items[4].double.map { $0 / 1000 }, position: items[5].double ?? 0,
            positionTimestamp: now, isPlaying: state == "playing")
        return (snapshot, art)
    }
}
