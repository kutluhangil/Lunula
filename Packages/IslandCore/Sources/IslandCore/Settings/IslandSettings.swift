import Foundation

public enum IslandFeature: String, Codable, Sendable, CaseIterable {
    case nowPlaying, timer, calendar, weather, shelf, battery, downloads, privacyIndicator, customActivities
}

public enum WeatherLocationSetting: Codable, Equatable, Sendable {
    case automatic
    case city(name: String, latitude: Double, longitude: Double)
}

public struct IslandSettings: Codable, Equatable, Sendable {
    public var displayMode: DisplayMode = .notchedOnly
    public var hideInFullscreen = true
    public var criticalAlertsInFullscreen = true
    public var launchAtLogin = false
    public var hapticsEnabled = true
    public var soundsEnabled = true
    /// 0...1
    public var haloIntensity: Double = 1.0
    public var enabledFeatures = Set(IslandFeature.allCases)
    public var weatherLocation: WeatherLocationSetting = .automatic
    public var temperatureUnit: TemperatureUnitPreference = .system
    public var shelfCopiesFiles = false
    /// `nil` = keep forever.
    public var shelfRetentionDays: Int? = 7
    public var showMenuBarIcon = false
    public var muteUntil: Date?
    public var hasCompletedOnboarding = false

    public static let `default` = IslandSettings()

    public init() {}

    public var islandOptions: IslandOptions {
        var options = IslandOptions()
        options.hideInFullscreen = hideInFullscreen
        options.criticalAlertsInFullscreen = criticalAlertsInFullscreen
        return options
    }

    private enum CodingKeys: String, CodingKey {
        case displayMode, hideInFullscreen, criticalAlertsInFullscreen, launchAtLogin, hapticsEnabled, soundsEnabled
        case haloIntensity, enabledFeatures, weatherLocation, temperatureUnit, shelfCopiesFiles, shelfRetentionDays
        case showMenuBarIcon, muteUntil, hasCompletedOnboarding
    }

    /// Missing, unknown or malformed keys fall back to the default per key, so old or future data never breaks.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = IslandSettings.default
        func value<T: Decodable>(_ key: CodingKeys, _ fallback: T) -> T {
            (try? c.decodeIfPresent(T.self, forKey: key)) ?? fallback
        }
        displayMode = value(.displayMode, d.displayMode)
        hideInFullscreen = value(.hideInFullscreen, d.hideInFullscreen)
        criticalAlertsInFullscreen = value(.criticalAlertsInFullscreen, d.criticalAlertsInFullscreen)
        launchAtLogin = value(.launchAtLogin, d.launchAtLogin)
        hapticsEnabled = value(.hapticsEnabled, d.hapticsEnabled)
        soundsEnabled = value(.soundsEnabled, d.soundsEnabled)
        haloIntensity = min(max(value(.haloIntensity, d.haloIntensity), 0), 1)
        enabledFeatures = value(.enabledFeatures, d.enabledFeatures)
        weatherLocation = value(.weatherLocation, d.weatherLocation)
        temperatureUnit = value(.temperatureUnit, d.temperatureUnit)
        shelfCopiesFiles = value(.shelfCopiesFiles, d.shelfCopiesFiles)
        // An explicit null means "never"; only a missing key takes the default.
        shelfRetentionDays =
            c.contains(.shelfRetentionDays)
            ? (try? c.decodeIfPresent(Int.self, forKey: .shelfRetentionDays)) ?? nil : d.shelfRetentionDays
        muteUntil = value(.muteUntil, d.muteUntil)
        hasCompletedOnboarding = value(.hasCompletedOnboarding, d.hasCompletedOnboarding)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(displayMode, forKey: .displayMode)
        try c.encode(hideInFullscreen, forKey: .hideInFullscreen)
        try c.encode(criticalAlertsInFullscreen, forKey: .criticalAlertsInFullscreen)
        try c.encode(launchAtLogin, forKey: .launchAtLogin)
        try c.encode(hapticsEnabled, forKey: .hapticsEnabled)
        try c.encode(soundsEnabled, forKey: .soundsEnabled)
        try c.encode(haloIntensity, forKey: .haloIntensity)
        try c.encode(enabledFeatures, forKey: .enabledFeatures)
        try c.encode(weatherLocation, forKey: .weatherLocation)
        try c.encode(temperatureUnit, forKey: .temperatureUnit)
        try c.encode(shelfCopiesFiles, forKey: .shelfCopiesFiles)
        try c.encode(shelfRetentionDays, forKey: .shelfRetentionDays)  // writes null for "never"
        try c.encodeIfPresent(muteUntil, forKey: .muteUntil)
        try c.encode(showMenuBarIcon, forKey: .showMenuBarIcon)
        try c.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
    }
}
