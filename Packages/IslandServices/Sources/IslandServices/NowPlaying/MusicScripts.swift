enum MusicScripts {
    static let bundleID = "com.apple.Music"

    static let query = PlayerScripts.wrap(
        bundleID,
        """
        if player state is stopped then return {"stopped"}
            set t to current track
            return {player state as text, name of t, artist of t, album of t, duration of t, player position, persistent ID of t}
        """)

    static let artwork = PlayerScripts.wrap(
        bundleID,
        "if (count of artworks of current track) > 0 then return raw data of artwork 1 of current track")

    static func command(_ command: PlaybackCommand) -> String { PlayerScripts.wrap(bundleID, PlayerScripts.command(command)) }
}
