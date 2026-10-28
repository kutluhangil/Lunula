import Foundation

public enum TemperatureUnitPreference: String, Codable, Sendable, CaseIterable { case system, celsius, fahrenheit }

public struct UnitChoice: Equatable, Sendable {
    public var temperature: TemperatureUnit
    public var speed: SpeedUnit

    public init(temperature: TemperatureUnit, speed: SpeedUnit) {
        self.temperature = temperature
        self.speed = speed
    }
}

public enum UnitPreferences {
    /// Precedence for temperature: `override` > `systemTemperatureSetting` ("Celsius"/"Fahrenheit") > locale.
    /// Speed always follows the locale's measurement system.
    public static func resolve(
        locale: Locale, systemTemperatureSetting: String?, override: TemperatureUnitPreference
    ) -> UnitChoice {
        let system = locale.measurementSystem
        let speed: SpeedUnit = (system == .us || system == .uk) ? .milesPerHour : .kilometersPerHour
        let temperature: TemperatureUnit
        switch (override, systemTemperatureSetting) {
        case (.celsius, _): temperature = .celsius
        case (.fahrenheit, _): temperature = .fahrenheit
        case (.system, "Celsius"?): temperature = .celsius
        case (.system, "Fahrenheit"?): temperature = .fahrenheit
        case (.system, _): temperature = system == .us ? .fahrenheit : .celsius
        }
        return UnitChoice(temperature: temperature, speed: speed)
    }
}
