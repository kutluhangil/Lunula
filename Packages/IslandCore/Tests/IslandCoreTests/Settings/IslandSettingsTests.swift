import Foundation
import Testing

@testable import IslandCore

@Suite struct IslandSettingsTests {
    @Test func decodingEmptyObjectGivesDefaults() throws {
        #expect(try JSONDecoder().decode(IslandSettings.self, from: Data("{}".utf8)) == .default)
    }

    @Test func decodingIgnoresUnknownKeysAndKeepsKnown() throws {
        let s = try JSONDecoder().decode(
            IslandSettings.self, from: Data(#"{"hapticsEnabled":false,"futureKey":1}"#.utf8))
        #expect(s.hapticsEnabled == false && s.displayMode == .notchedOnly)
    }

    @Test func roundTripPreservesValues() throws {
        var s = IslandSettings.default
        s.weatherLocation = .city(name: "İzmir", latitude: 38.42, longitude: 27.14)
        s.shelfRetentionDays = nil
        #expect(try JSONDecoder().decode(IslandSettings.self, from: JSONEncoder().encode(s)) == s)
    }
}
