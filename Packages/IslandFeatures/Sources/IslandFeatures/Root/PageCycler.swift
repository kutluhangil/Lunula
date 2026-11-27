import IslandCore

/// Left/right arrow navigation between the expanded island's tabs and optional activity pages;
/// an unlisted activity page returns to home.
enum PageCycler {
    static let pages: [IslandPage] = [.home, .shelf, .tools]

    static func pages(activityPages: [IslandPage]) -> [IslandPage] {
        pages + activityPages
    }

    static func pages(activities: [ActivityID]) -> [IslandPage] {
        pages + activities.map(IslandPage.activity)
    }

    static func next(after page: IslandPage, activityPages: [IslandPage] = []) -> IslandPage {
        step(page, by: 1, in: pages(activityPages: activityPages))
    }

    static func previous(before page: IslandPage, activityPages: [IslandPage] = []) -> IslandPage {
        step(page, by: -1, in: pages(activityPages: activityPages))
    }

    static func next(after page: IslandPage, activities: [ActivityID]) -> IslandPage {
        step(page, by: 1, in: pages(activities: activities))
    }

    static func previous(before page: IslandPage, activities: [ActivityID]) -> IslandPage {
        step(page, by: -1, in: pages(activities: activities))
    }

    private static func step(_ page: IslandPage, by delta: Int, in cycle: [IslandPage]) -> IslandPage {
        guard !cycle.isEmpty, let index = cycle.firstIndex(of: page) else { return .home }
        return cycle[(index + delta + cycle.count) % cycle.count]
    }
}
