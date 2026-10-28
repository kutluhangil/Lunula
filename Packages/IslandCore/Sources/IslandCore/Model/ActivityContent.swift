public enum ActivityKind: String, Codable, CaseIterable, Sendable {
    case nowPlaying, timer, calendar, custom
}

public enum ActivityContent: Equatable, Sendable {
    case nowPlaying(NowPlayingSnapshot)
    case timer(TimerSnapshot)
    case calendar(EventSnapshot)
    case custom(CustomActivitySnapshot)

    public var kind: ActivityKind {
        switch self {
        case .nowPlaying: .nowPlaying
        case .timer: .timer
        case .calendar: .calendar
        case .custom: .custom
        }
    }
}
