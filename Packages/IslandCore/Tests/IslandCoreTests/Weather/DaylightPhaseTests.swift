import Foundation
import Testing

@testable import IslandCore

@Suite struct DaylightPhaseTests {
    let sunrise = Date(timeIntervalSinceReferenceDate: 6 * 3600)
    let sunset = Date(timeIntervalSinceReferenceDate: 18 * 3600)

    @Test func dawnWindowIs45MinutesAroundSunrise() {
        #expect(
            DaylightPhase.phase(
                now: sunrise.addingTimeInterval(-40 * 60), sunrise: sunrise, sunset: sunset, isDaylight: false)
                == .dawn)
        #expect(
            DaylightPhase.phase(
                now: sunrise.addingTimeInterval(50 * 60), sunrise: sunrise, sunset: sunset, isDaylight: true)
                == .day)
    }

    @Test func nightAfterDusk() {
        #expect(
            DaylightPhase.phase(
                now: sunset.addingTimeInterval(2 * 3600), sunrise: sunrise, sunset: sunset, isDaylight: false)
                == .night)
    }

    @Test func missingTimesFallBackToIsDaylight() {
        #expect(DaylightPhase.phase(now: sunrise, sunrise: nil, sunset: nil, isDaylight: true) == .day)
    }
}
