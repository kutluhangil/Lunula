import Foundation

public struct GeoPlace: Equatable, Sendable, Codable {
    public var name: String
    public var admin1: String?
    public var country: String?
    public var latitude: Double
    public var longitude: Double

    public init(name: String, admin1: String?, country: String?, latitude: Double, longitude: Double) {
        self.name = name
        self.admin1 = admin1
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
    }
}

public protocol WeatherProviding: Sendable {
    func current(latitude: Double, longitude: Double, now: Date) async throws -> WeatherSnapshot
    func search(_ query: String, language: String) async throws -> [GeoPlace]
}
