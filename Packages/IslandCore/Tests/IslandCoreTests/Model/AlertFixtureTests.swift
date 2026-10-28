import IslandCoreTestSupport
import Testing

@testable import IslandCore

@Suite struct AlertFixtureTests {
    @Test func fixtureDetailMatchesKind() {
        #expect(TransientAlert.fixture(kind: .batteryLow).detail == .batteryLevel(10))
        guard case .text = TransientAlert.fixture(kind: .custom).detail else {
            Issue.record("expected text detail")
            return
        }
    }
}
