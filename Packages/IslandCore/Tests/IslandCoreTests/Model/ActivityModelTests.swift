import Foundation
import IslandCoreTestSupport
import Testing

@testable import IslandCore

@Suite struct ActivityModelTests {
    @Test func kindDerivesFromContent() {
        #expect(Activity.fixture(content: .nowPlaying(.fixture())).kind == .nowPlaying)
        #expect(
            Activity.fixture(
                content: .custom(.init(title: "x", subtitle: nil, symbol: nil, progress: nil, endsAt: nil))
            ).kind == .custom)
    }
    @Test func priorityOrderIsAmbientNormalHighCritical() {
        #expect(ActivityPriority.allCases.sorted() == [.ambient, .normal, .high, .critical])
    }
}
