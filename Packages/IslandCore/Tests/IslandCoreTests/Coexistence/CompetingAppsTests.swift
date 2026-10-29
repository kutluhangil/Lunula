import Testing

@testable import IslandCore

@Suite struct CompetingAppsTests {
    @Test func detectsKnownCompetitorOnce() {
        let boringNotch = "theboringteam.boringnotch"
        #expect(CompetingApps.detect(running: [boringNotch], alreadyNotified: []) == boringNotch)
        #expect(CompetingApps.detect(running: [boringNotch], alreadyNotified: [boringNotch]) == nil)
    }
}
