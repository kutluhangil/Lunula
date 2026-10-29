import Foundation
import IslandCore

public struct OpenMeteoProvider: WeatherProviding {
    private let session: URLSession

    public init(session: URLSession = .shared) { self.session = session }

    public func current(latitude: Double, longitude: Double, now: Date) async throws -> WeatherSnapshot {
        try OpenMeteoParser.forecast(
            try await fetch(OpenMeteoParser.forecastURL(latitude: latitude, longitude: longitude)), fetchedAt: now)
    }

    public func search(_ query: String, language: String) async throws -> [GeoPlace] {
        try OpenMeteoParser.places(try await fetch(OpenMeteoParser.geocodingURL(query: query, language: language)))
    }

    private func fetch(_ url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return data
    }
}
