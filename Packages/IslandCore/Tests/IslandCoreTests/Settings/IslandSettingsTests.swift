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
        s.displayMode = .allDisplays
        s.hideInFullscreen = false
        s.criticalAlertsInFullscreen = false
        s.launchAtLogin = true
        s.hapticsEnabled = false
        s.soundsEnabled = false
        s.haloIntensity = 0.5
        s.enabledFeatures = [.nowPlaying, .timer]
        s.weatherLocation = .city(name: "İzmir", latitude: 38.42, longitude: 27.14)
        s.temperatureUnit = .fahrenheit
        s.shelfCopiesFiles = true
        s.shelfRetentionDays = nil
        s.showMenuBarIcon = true
        s.muteUntil = Date(timeIntervalSinceReferenceDate: 800_000_000)
        s.hasCompletedOnboarding = true
        #expect(try JSONDecoder().decode(IslandSettings.self, from: JSONEncoder().encode(s)) == s)
    }

    @Test func unknownDisabledFeatureIsIgnored() throws {
        let s = try JSONDecoder().decode(
            IslandSettings.self, from: Data(#"{"disabledFeatures":["weather","futureThing"]}"#.utf8))
        #expect(s.enabledFeatures == Set(IslandFeature.allCases).subtracting([.weather]))
    }

    @Test func malformedRetentionFallsBackToDefault() throws {
        let s = try JSONDecoder().decode(IslandSettings.self, from: Data(#"{"shelfRetentionDays":"x"}"#.utf8))
        #expect(s.shelfRetentionDays == 7)
    }

    @Test func nullRetentionMeansNever() throws {
        let s = try JSONDecoder().decode(IslandSettings.self, from: Data(#"{"shelfRetentionDays":null}"#.utf8))
        #expect(s.shelfRetentionDays == nil)
    }
}
