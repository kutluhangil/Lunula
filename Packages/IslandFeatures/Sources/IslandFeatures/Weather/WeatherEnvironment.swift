import IslandCore
import SwiftUI

/// Weather for the home tile and the daylight halo, read inside view bodies so Observation keeps them live.
public struct WeatherInfo {
    public var current: @MainActor () -> (snapshot: WeatherSnapshot, units: UnitChoice)? = { nil }

    public init(current: @escaping @MainActor () -> (snapshot: WeatherSnapshot, units: UnitChoice)?) {
        self.current = current
    }

    init() {}
}

extension EnvironmentValues {
    @Entry public var weatherInfo = WeatherInfo()
}
