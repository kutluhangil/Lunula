import IslandCore

/// Left/right arrow navigation between the expanded island's tabs; an activity page returns to home.
enum PageCycler {
    static let pages: [IslandPage] = [.home, .shelf]

    static func next(after page: IslandPage) -> IslandPage { step(page, by: 1) }
    static func previous(before page: IslandPage) -> IslandPage { step(page, by: -1) }

    private static func step(_ page: IslandPage, by delta: Int) -> IslandPage {
        guard let index = pages.firstIndex(of: page) else { return .home }
        return pages[(index + delta + pages.count) % pages.count]
    }
}
