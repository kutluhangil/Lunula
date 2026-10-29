import IslandCore

enum WeatherSymbol {
    static func name(_ condition: WeatherCondition, isDaylight: Bool) -> String {
        switch condition {
        case .clear: isDaylight ? "sun.max.fill" : "moon.stars.fill"
        case .partlyCloudy: isDaylight ? "cloud.sun.fill" : "cloud.moon.fill"
        case .cloudy: "cloud.fill"
        case .fog: "cloud.fog.fill"
        case .drizzle: "cloud.drizzle.fill"
        case .rain: "cloud.rain.fill"
        case .snow: "cloud.snow.fill"
        case .thunderstorm: "cloud.bolt.rain.fill"
        }
    }
}
