import Foundation
import IslandCore

@testable import IslandServices

enum Fixture {
    static func data(_ name: String) throws -> Data {
        let url = try required(Bundle.module.url(forResource: "Resources/\(name)", withExtension: nil))
        return try Data(contentsOf: url)
    }

    private static func required<T>(_ value: T?) throws -> T {
        guard let value else { throw CocoaError(.fileNoSuchFile) }
        return value
    }
}

final class FakeWeather: WeatherProviding, @unchecked Sendable {  // main-actor tests only
    let fails: Bool
    private(set) var calls = 0

    init(fails: Bool = false) { self.fails = fails }

    func current(latitude: Double, longitude: Double, now: Date) async throws -> WeatherSnapshot {
        calls += 1
        if fails { throw URLError(.notConnectedToInternet) }
        return .fixture(fetchedAt: now)
    }

    func search(_ query: String, language: String) async throws -> [GeoPlace] { [] }
}

struct FakeLocation: LocationProviding {
    func currentCoordinate() async throws -> (latitude: Double, longitude: Double) { (41.01, 28.98) }
}
