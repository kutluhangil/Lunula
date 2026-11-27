import IslandCore
import Testing

@testable import IslandFeatures

@Suite struct PageCyclerTests {
    @Test func arrowsCyclePages() {
        #expect(PageCycler.next(after: .home) == .shelf)
        #expect(PageCycler.next(after: .shelf) == .tools)
        #expect(PageCycler.next(after: .tools) == .home)

        #expect(PageCycler.previous(before: .home) == .tools)
        #expect(PageCycler.previous(before: .tools) == .shelf)
        #expect(PageCycler.previous(before: .shelf) == .home)

        #expect(PageCycler.previous(before: .activity("x")) == .home)

        let activityPages: [IslandPage] = [.activity("a"), .activity("b")]
        #expect(PageCycler.next(after: .tools, activityPages: activityPages) == .activity("a"))
        #expect(PageCycler.next(after: .activity("a"), activityPages: activityPages) == .activity("b"))
        #expect(PageCycler.next(after: .activity("b"), activityPages: activityPages) == .home)
        #expect(PageCycler.previous(before: .home, activityPages: activityPages) == .activity("b"))
    }
}
