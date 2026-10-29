import Foundation
import IslandCore

/// Open-Meteo forecast and geocoding (no key; attribution CC BY 4.0 in About).
public enum OpenMeteoParser {
    private struct Forecast: Decodable {
        struct Current: Decodable {
            var temperature2m: Double
            var weatherCode: Int
            var isDay: Int

            enum CodingKeys: String, CodingKey {
                case temperature2m = "temperature_2m"
                case weatherCode = "weather_code"
                case isDay = "is_day"
            }
        }
        struct Daily: Decodable {
            var temperature2mMax: [Double]
            var temperature2mMin: [Double]
            var sunrise: [String]
            var sunset: [String]

            enum CodingKeys: String, CodingKey {
                case temperature2mMax = "temperature_2m_max"
                case temperature2mMin = "temperature_2m_min"
                case sunrise
                case sunset
            }
        }
        var utcOffsetSeconds: Int
        var current: Current
        var daily: Daily

        enum CodingKeys: String, CodingKey {
            case utcOffsetSeconds = "utc_offset_seconds"
            case current
            case daily
        }
    }

    private struct Places: Decodable { var results: [GeoPlace]? }

    public static func forecast(_ data: Data, fetchedAt: Date) throws -> WeatherSnapshot {
        let f = try JSONDecoder().decode(Forecast.self, from: data)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.timeZone = TimeZone(secondsFromGMT: f.utcOffsetSeconds)
        return WeatherSnapshot(
            temperatureC: f.current.temperature2m, highC: f.daily.temperature2mMax.first ?? f.current.temperature2m,
            lowC: f.daily.temperature2mMin.first ?? f.current.temperature2m,
            condition: condition(wmoCode: f.current.weatherCode), isDaylight: f.current.isDay == 1,
            sunrise: f.daily.sunrise.first.flatMap(formatter.date(from:)),
            sunset: f.daily.sunset.first.flatMap(formatter.date(from:)), placeName: nil, fetchedAt: fetchedAt)
    }

    public static func places(_ data: Data) throws -> [GeoPlace] {
        try JSONDecoder().decode(Places.self, from: data).results ?? []
    }

    public static func condition(wmoCode: Int) -> WeatherCondition {
        switch wmoCode {
        case 0: .clear
        case 1, 2: .partlyCloudy
        case 3: .cloudy
        case 45, 48: .fog
        case 51...57: .drizzle
        case 61...67, 80...82: .rain
        case 71...77, 85, 86: .snow
        case 95...99: .thunderstorm
        default: .cloudy
        }
    }

    /// Coordinates rounded to 2 decimals (~1 km): privacy and cache friendliness.
    public static func forecastURL(latitude: Double, longitude: Double) -> URL {
        var c = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        c.queryItems = [
            .init(name: "latitude", value: String(format: "%.2f", latitude)),
            .init(name: "longitude", value: String(format: "%.2f", longitude)),
            .init(name: "current", value: "temperature_2m,weather_code,is_day"),
            .init(name: "daily", value: "temperature_2m_max,temperature_2m_min,sunrise,sunset"),
            .init(name: "timezone", value: "auto"),
            .init(name: "forecast_days", value: "1"),
        ]
        return c.url!
    }

    public static func geocodingURL(query: String, language: String) -> URL {
        var c = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        c.queryItems = [
            .init(name: "name", value: query), .init(name: "count", value: "5"),
            .init(name: "language", value: language), .init(name: "format", value: "json"),
        ]
        return c.url!
    }
}
