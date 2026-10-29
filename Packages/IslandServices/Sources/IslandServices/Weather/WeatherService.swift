import Foundation
import IslandCore
import Observation

/// Weather for the home page. Fetches only when the island's home becomes visible and the cache is older than
/// 30 minutes; on failure the last value stays.
@MainActor @Observable public final class WeatherService {
    @ObservationIgnored private let provider: WeatherProviding
    @ObservationIgnored private let cache: WeatherCache
    @ObservationIgnored private let location: LocationProviding
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let time: IslandTime
    @ObservationIgnored private var inFlight = false

    public private(set) var snapshot: WeatherSnapshot?

    public init(
        provider: WeatherProviding, cache: WeatherCache, location: LocationProviding, settings: SettingsStore,
        time: IslandTime
    ) {
        self.provider = provider
        self.cache = cache
        self.location = location
        self.settings = settings
        self.time = time
        snapshot = cache.load()
    }

    public func islandBecameVisible() async {
        let now = time.now
        if let snapshot, WeatherCache.isFresh(snapshot, now: now) { return }
        guard !inFlight else { return }
        inFlight = true
        defer { inFlight = false }
        do {
            var fresh: WeatherSnapshot
            switch settings.settings.weatherLocation {
            case .city(let name, let latitude, let longitude):
                fresh = try await provider.current(latitude: latitude, longitude: longitude, now: now)
                fresh.placeName = name  // only a manually chosen city is shown; no reverse geocoding
            case .automatic:
                let c = try await location.currentCoordinate()
                fresh = try await provider.current(latitude: c.latitude, longitude: c.longitude, now: now)
            }
            snapshot = fresh
            cache.save(fresh)
        } catch {
            // Keep the last value.
        }
    }

    public func search(_ query: String, language: String) async -> [GeoPlace] {
        (try? await provider.search(query, language: language)) ?? []
    }
}
