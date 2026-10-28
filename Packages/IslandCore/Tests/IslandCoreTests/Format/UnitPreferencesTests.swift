import Foundation
import Testing

@testable import IslandCore

@Suite struct UnitPreferencesTests {
    @Test func turkishLocaleUsesCelsiusAndKmh() {
        let u = UnitPreferences.resolve(
            locale: Locale(identifier: "tr_TR"), systemTemperatureSetting: nil, override: .system)
        #expect(u == UnitChoice(temperature: .celsius, speed: .kilometersPerHour))
    }
    @Test func usLocaleUsesFahrenheitAndMph() {
        #expect(
            UnitPreferences.resolve(
                locale: Locale(identifier: "en_US"), systemTemperatureSetting: nil, override: .system)
                == UnitChoice(temperature: .fahrenheit, speed: .milesPerHour))
    }
    @Test func ukLocaleUsesCelsiusAndMph() {
        #expect(
            UnitPreferences.resolve(
                locale: Locale(identifier: "en_GB"), systemTemperatureSetting: nil, override: .system)
                == UnitChoice(temperature: .celsius, speed: .milesPerHour))
    }
    @Test func systemTemperatureSettingWinsOverLocale() {
        #expect(
            UnitPreferences.resolve(
                locale: Locale(identifier: "tr_TR"), systemTemperatureSetting: "Fahrenheit", override: .system
            ).temperature == .fahrenheit)
    }
    @Test func explicitOverrideWinsOverEverything() {
        #expect(
            UnitPreferences.resolve(
                locale: Locale(identifier: "en_US"), systemTemperatureSetting: "Fahrenheit", override: .celsius
            ).temperature == .celsius)
    }
}
