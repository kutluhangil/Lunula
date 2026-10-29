import IslandCore
import Testing

@testable import IslandFeatures

@Suite struct PageCyclerTests {
    @Test func arrowsCyclePages() {
        #expect(PageCycler.next(after: .home) == .shelf && PageCycler.next(after: .shelf) == .home)
        #expect(PageCycler.previous(before: .activity("x")) == .home)
    }
}
