enum SpotifyScripts {
    static let bundleID = "com.spotify.client"

    static let query = PlayerScripts.wrap(
        bundleID,
        """
        if player state is stopped then return {"stopped"}
            set t to current track
            return {player state as text, name of t, artist of t, album of t, duration of t, player position, id of t, artwork url of t}
        """)

    static func command(_ command: PlaybackCommand) -> String {
        PlayerScripts.wrap(bundleID, PlayerScripts.command(command))
    }
}
