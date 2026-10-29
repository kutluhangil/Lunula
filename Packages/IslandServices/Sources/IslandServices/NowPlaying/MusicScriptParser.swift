import Foundation
import IslandCore

enum MusicScriptParser {
    /// `{state, name, artist, album, duration s, position s, persistent ID}`; stopped or a blank name (streams and
    /// radio on Tahoe can return garbage) yields nil: no info beats wrong info.
    static func parse(_ value: ScriptValue, now: Date) -> NowPlayingSnapshot? {
        guard let items = PlayerScripts.texts(value), items.count >= 7, let state = items[0].string,
            state != "stopped", let title = items[1].string, !title.isEmpty, let id = items[6].string
        else { return nil }
        return NowPlayingSnapshot(
            source: .music, trackID: id, title: title, artist: items[2].string ?? "", album: items[3].string,
            artworkKey: "music:" + id, duration: items[4].double, position: items[5].double ?? 0,
            positionTimestamp: now, isPlaying: state == "playing")
    }
}
