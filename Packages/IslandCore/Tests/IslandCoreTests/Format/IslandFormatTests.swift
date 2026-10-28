import Foundation
import Testing

@testable import IslandCore

@Suite struct IslandFormatTests {
    @Test(arguments: [(65.0, "1:05"), (59.2, "1:00"), (3725.0, "1:02:05"), (-3.0, "0:00"), (0.4, "0:01")])
    func countdown(_ input: Double, _ expected: String) { #expect(IslandFormat.countdown(input) == expected) }
    @Test func trackTimeFloors() { #expect(IslandFormat.trackTime(187.9) == "3:07") }
    @Test func temperatureRoundsAndDropsNegativeZero() {
        #expect(IslandFormat.temperature(celsius: 21.5, unit: .celsius) == "22°")
        #expect(IslandFormat.temperature(celsius: -0.4, unit: .celsius) == "0°")
        #expect(IslandFormat.temperature(celsius: -3.2, unit: .celsius) == "-3°")
    }
    @Test func nonFiniteInputDoesNotCrash() {
        #expect(IslandFormat.countdown(.infinity) == "0:00")
        #expect(IslandFormat.trackTime(.nan) == "0:00")
        #expect(IslandFormat.temperature(celsius: .nan, unit: .celsius) == "--°")
    }
    @Test func temperatureConvertsToFahrenheit() {
        #expect(IslandFormat.temperature(celsius: 20, unit: .fahrenheit) == "68°")
    }
}
