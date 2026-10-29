import Foundation
import IslandCore
import IslandCoreTestSupport
import Testing

@testable import IslandServices

@Suite struct OpenMeteoParserTests {
    @Test(arguments: [
        (0, WeatherCondition.clear), (2, .partlyCloudy), (3, .cloudy), (45, .fog), (53, .drizzle), (63, .rain),
        (81, .rain), (73, .snow), (86, .snow), (95, .thunderstorm), (99, .thunderstorm), (42, .cloudy),
    ])
    func wmoCodesMapToConditions(code: Int, expected: WeatherCondition) {
        #expect(OpenMeteoParser.condition(wmoCode: code) == expected)
    }

    @Test func parsesForecastFixture() throws {
        let s = try OpenMeteoParser.forecast(Fixture.data("open-meteo-forecast.json"), fetchedAt: .distantPast)
        #expect(
            s.temperatureC == 18.4 && s.highC == 21.2 && s.lowC == 12.9 && s.condition == .partlyCloudy && s.isDaylight)
    }

    @Test func parsesGeocodingFixtureInTurkish() throws {
        #expect(try OpenMeteoParser.places(Fixture.data("open-meteo-geocoding-tr.json")).first?.name == "İzmir")
    }

    @Test func forecastURLRoundsCoordinates() {
        #expect(
            OpenMeteoParser.forecastURL(latitude: 41.008237, longitude: 28.978358).query?.contains(
                "latitude=41.01&longitude=28.98") == true)
    }
}

@MainActor @Suite struct WeatherServiceTests {
    let time = ManualTime()

    func make(provider: FakeWeather, cached: WeatherSnapshot?) -> WeatherService {
        let cache = WeatherCache(
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("weather-\(UUID().uuidString).json"))
        if let cached { cache.save(cached) }
        return WeatherService(
            provider: provider, cache: cache, location: FakeLocation(),
            settings: SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!), time: time)
    }

    @Test func cacheServedWithin30Minutes() async {
        let p = FakeWeather()
        let s = make(provider: p, cached: .fixture(fetchedAt: time.now.addingTimeInterval(-600)))
        await s.islandBecameVisible()
        #expect(p.calls == 0 && s.snapshot != nil)
    }

    @Test func staleCacheFetches() async {
        let p = FakeWeather()
        let s = make(provider: p, cached: .fixture(fetchedAt: time.now.addingTimeInterval(-3600)))
        await s.islandBecameVisible()
        #expect(p.calls == 1)
    }

    @Test func networkFailureKeepsLastCachedValue() async {
        let cached = WeatherSnapshot.fixture(fetchedAt: time.now.addingTimeInterval(-3600))
        let s = make(provider: FakeWeather(fails: true), cached: cached)
        await s.islandBecameVisible()
        #expect(s.snapshot == cached)
    }

    @Test func nothingFetchedUntilIslandVisible() async {
        let p = FakeWeather()
        _ = make(provider: p, cached: nil)
        await settle()
        #expect(p.calls == 0)
    }
}
