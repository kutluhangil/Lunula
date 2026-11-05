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
        let body: String =
            switch command {
            case .toggleShuffle: "set shuffling to not shuffling"
            case .cycleRepeat: "set repeating to not repeating"
            case .toggleFavorite: ""
            default: PlayerScripts.command(command)
            }
        return PlayerScripts.wrap(bundleID, body)
    }
}
