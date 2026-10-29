import Foundation
import IslandCore

/// Apple Music through its scripting access groups (com.apple.Music.playback / .playerInfo).
public final class MusicSource: NowPlayingSource {
    public let id: MediaSourceID = .music
    public let bundleID = MusicScripts.bundleID
    public let notificationName = Notification.Name("com.apple.Music.playerInfo")
    private let runner: ScriptRunner

    public init(runner: ScriptRunner) { self.runner = runner }

    public func snapshot(now: Date) async -> NowPlayingSnapshot? {
        guard case .success(let value) = await runner.run(MusicScripts.query, target: bundleID) else { return nil }
        return MusicScriptParser.parse(value, now: now)
    }

    public func artwork(for trackID: String) async -> Data? {
        guard case .success(.data(let data)) = await runner.run(MusicScripts.artwork, target: bundleID) else { return nil }
        return data
    }

    public func perform(_ command: PlaybackCommand) async {
        _ = await runner.run(MusicScripts.command(command), target: bundleID)
    }
}
