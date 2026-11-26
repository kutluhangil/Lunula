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
        s.fullChargeThreshold = 85
        s.bluetoothAlertsEnabled = false
        s.timerMascot = .cat
        s.pillVerticalOffset = 4
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

    @Test func quickToolOrderNormalizesAndFiltersEnabledTools() throws {
        let json = #"{"enabledQuickTools":["kbd","awake"],"quickToolOrder":["kbd","unknown","awake","kbd"]}"#
        let s = try JSONDecoder().decode(IslandSettings.self, from: Data(json.utf8))
        #expect(s.orderedEnabledQuickTools == ["kbd", "awake"])
        #expect(s.quickToolOrder.count == QuickToolID.allCases.count)
        #expect(s.quickToolOrder.prefix(2) == ["kbd", "awake"])
    }

    @Test func expandedWidthPomodoroAndGesturesRoundTripAndClamp() throws {
        var s = IslandSettings.default
        s.expandedWidth = 560
        s.pomodoroPlan = PomodoroPlan(focus: 1800, shortBreak: 600, longBreak: 1200, focusSessionsBeforeLongBreak: 3)
        s.hoverToPeekEnabled = false
        s.swipeGesturesEnabled = false
        let decoded = try JSONDecoder().decode(IslandSettings.self, from: JSONEncoder().encode(s))
        #expect(decoded == s)
        #expect(
            decoded.islandOptions.hoverToPeekEnabled == false && decoded.islandOptions.swipeGesturesEnabled == false)

        let clamped = try JSONDecoder().decode(
            IslandSettings.self, from: Data(#"{"expandedWidth":900}"#.utf8))
        #expect(clamped.expandedWidth == 600)
    }
}
