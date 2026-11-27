import Foundation

public enum IslandFeature: String, Codable, Sendable, CaseIterable {
    case nowPlaying, timer, calendar, weather, shelf, battery, downloads, privacyIndicator, customActivities
}

public enum WeatherLocationSetting: Codable, Equatable, Sendable {
    case automatic
    case city(name: String, latitude: Double, longitude: Double)
}

public enum QuickToolID: String, Codable, Equatable, Sendable, CaseIterable, Identifiable {
    case awake, mic, out, drop, notes, clip, search, prompt, stats, stocks, kbd, ai, mirror, record

    public var id: String { rawValue }

    public static let defaultOrder: [String] = allCases.map(\.rawValue)
    public static let defaultEnabledOrder: [String] = ["awake", "mic", "out", "drop", "notes", "clip"]

    public static func normalizedOrder(_ raw: [String]) -> [String] {
        let valid = Set(defaultOrder)
        var seen: Set<String> = []
        var result: [String] = []
        for key in raw where valid.contains(key) && seen.insert(key).inserted {
            result.append(key)
        }
        for key in defaultOrder where seen.insert(key).inserted {
            result.append(key)
        }
        return result
    }
}

public enum TimerMascot: String, Codable, Equatable, Sendable, CaseIterable {
    case none, hare, tortoise, cat, bird, flame

    public var symbolName: String? {
        switch self {
        case .none: nil
        case .hare: "hare.fill"
        case .tortoise: "tortoise.fill"
        case .cat: "cat.fill"
        case .bird: "bird.fill"
        case .flame: "flame.fill"
        }
    }
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
    /// Download alerts watch ~/Downloads, which can raise a privacy prompt; they start only after the user opts in.
    public var downloadsAlertsOptedIn = false
    /// Competing notch apps already mentioned (CompetingApps), so each notice appears once.
    public var notifiedCompetitors: Set<String> = []
    /// Full-charge alert threshold (80...100%).
    public var fullChargeThreshold: Int = 100
    /// Show transient island alert when a Bluetooth or external audio device connects.
    public var bluetoothAlertsEnabled = true
    /// Optional SF Symbol mascot shown next to running timers.
    public var timerMascot: TimerMascot = .none
    /// Vertical offset (0...8 pt) for pill mode on displays without a hardware notch.
    public var pillVerticalOffset: Double = 0
    /// Turns the top menu-bar strip #000000 on notched displays to visually hide the hardware notch.
    public var hideNotchBar = false
    /// Adds a subtle specular Liquid Glass highlight to inner cards while keeping the island core opaque #000000.
    public var useGlassCards = false
    /// Double-tapping Option (⌥) toggles the island ("Knock to Control" double-tap-a-key mode).
    public var doubleTapOptionToToggle = true
    /// Expanded island width in points (520...600 pt).
    public var expandedWidth: Double = 520
    /// Configurable Pomodoro focus, break, and cycle plan.
    public var pomodoroPlan: PomodoroPlan = .standard
    /// Hovering the notch/pill opens peek preview after dwell.
    public var hoverToPeekEnabled = true
    /// Two-finger vertical swipes open and close the island.
    public var swipeGesturesEnabled = true
    /// Tools enabled in the expanded island top bar.
    public var enabledQuickTools: Set<String> = Set(QuickToolID.defaultEnabledOrder)
    /// Display order of all quick tools in Settings and the expanded island top bar.
    public var quickToolOrder: [String] = QuickToolID.defaultOrder
    /// Elastic surface-tension deformation and specular highlight when hovering near the island.
    public var waterDropletEffect = true
    /// Sensitivity preset scaling elastic water-droplet pull distance.
    public var dropletSensitivity: DropletSensitivity = .balanced
    /// High-level aesthetic personality of the island shell and inner layout.
    public var visualStyle: IslandVisualStyle = .lunula
    /// Outer shell material of the island surface.
    public var surfaceMaterial: IslandSurfaceMaterial = .obsidian
    /// Shows live synced lyric line in the right compact wing when available.
    public var compactWingLyrics = true
    /// Shows a floating shelf drop basket when dragging files.
    public var floatingShelfBasket = true
    /// Enables live audio spectrum bars on Now Playing surfaces.
    public var liveAudioSpectrumEnabled = false
    /// Provider, model, and local endpoint configuration for Quick AI.
    public var quickAIConfig = QuickAIConfig()

    /// Enabled quick tools ordered according to `quickToolOrder`.
    public var orderedEnabledQuickTools: [String] {
        QuickToolID.normalizedOrder(quickToolOrder).filter { enabledQuickTools.contains($0) }
    }

    public static let `default` = IslandSettings()

    public init() {}

    public var islandOptions: IslandOptions {
        var options = IslandOptions()
        options.hideInFullscreen = hideInFullscreen
        options.criticalAlertsInFullscreen = criticalAlertsInFullscreen
        options.hoverToPeekEnabled = hoverToPeekEnabled
        options.swipeGesturesEnabled = swipeGesturesEnabled
        return options
    }

    private enum CodingKeys: String, CodingKey {
        case displayMode, hideInFullscreen, criticalAlertsInFullscreen, launchAtLogin, hapticsEnabled, soundsEnabled
        case haloIntensity, disabledFeatures, weatherLocation, temperatureUnit, shelfCopiesFiles, shelfRetentionDays
        case showMenuBarIcon, muteUntil, hasCompletedOnboarding, downloadsAlertsOptedIn
        case notifiedCompetitors, fullChargeThreshold, bluetoothAlertsEnabled, timerMascot, pillVerticalOffset,
            hideNotchBar, useGlassCards
        case doubleTapOptionToToggle, expandedWidth, pomodoroPlan, hoverToPeekEnabled, swipeGesturesEnabled
        case enabledQuickTools, quickToolOrder
        case waterDropletEffect, dropletSensitivity, visualStyle, surfaceMaterial, compactWingLyrics,
            floatingShelfBasket, liveAudioSpectrumEnabled, quickAIConfig
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
        showMenuBarIcon = value(.showMenuBarIcon, d.showMenuBarIcon)
        // Persist the complement so features added later default to on and unknown strings are ignored.
        let disabled = ((try? c.decodeIfPresent([String].self, forKey: .disabledFeatures)) ?? nil) ?? []
        enabledFeatures = Set(IslandFeature.allCases).subtracting(disabled.compactMap(IslandFeature.init(rawValue:)))
        weatherLocation = value(.weatherLocation, d.weatherLocation)
        temperatureUnit = value(.temperatureUnit, d.temperatureUnit)
        shelfCopiesFiles = value(.shelfCopiesFiles, d.shelfCopiesFiles)
        // An explicit null means "never"; only a missing key takes the default.
        if c.contains(.shelfRetentionDays), (try? c.decodeNil(forKey: .shelfRetentionDays)) == true {
            shelfRetentionDays = nil
        } else {
            shelfRetentionDays = value(.shelfRetentionDays, d.shelfRetentionDays)
        }
        muteUntil = value(.muteUntil, d.muteUntil)
        hasCompletedOnboarding = value(.hasCompletedOnboarding, d.hasCompletedOnboarding)
        downloadsAlertsOptedIn = value(.downloadsAlertsOptedIn, d.downloadsAlertsOptedIn)
        notifiedCompetitors = value(.notifiedCompetitors, d.notifiedCompetitors)
        fullChargeThreshold = min(max(value(.fullChargeThreshold, d.fullChargeThreshold), 80), 100)
        bluetoothAlertsEnabled = value(.bluetoothAlertsEnabled, d.bluetoothAlertsEnabled)
        timerMascot = value(.timerMascot, d.timerMascot)
        pillVerticalOffset = min(max(value(.pillVerticalOffset, d.pillVerticalOffset), 0), 8)
        hideNotchBar = value(.hideNotchBar, d.hideNotchBar)
        useGlassCards = value(.useGlassCards, d.useGlassCards)
        doubleTapOptionToToggle = value(.doubleTapOptionToToggle, d.doubleTapOptionToToggle)
        expandedWidth = min(max(value(.expandedWidth, d.expandedWidth), 520), 600)
        let rawPlan = value(.pomodoroPlan, d.pomodoroPlan)
        pomodoroPlan = PomodoroPlan(
            focus: min(max(rawPlan.focus, 300), 5400),
            shortBreak: min(max(rawPlan.shortBreak, 60), 1800),
            longBreak: min(max(rawPlan.longBreak, 300), 3600),
            focusSessionsBeforeLongBreak: min(max(rawPlan.focusSessionsBeforeLongBreak, 2), 8))
        hoverToPeekEnabled = value(.hoverToPeekEnabled, d.hoverToPeekEnabled)
        swipeGesturesEnabled = value(.swipeGesturesEnabled, d.swipeGesturesEnabled)
        enabledQuickTools = value(.enabledQuickTools, d.enabledQuickTools)
        quickToolOrder = QuickToolID.normalizedOrder(value(.quickToolOrder, d.quickToolOrder))
        waterDropletEffect = value(.waterDropletEffect, d.waterDropletEffect)
        dropletSensitivity = value(.dropletSensitivity, d.dropletSensitivity)
        visualStyle = value(.visualStyle, d.visualStyle)
        surfaceMaterial = value(.surfaceMaterial, d.surfaceMaterial)
        compactWingLyrics = value(.compactWingLyrics, d.compactWingLyrics)
        floatingShelfBasket = value(.floatingShelfBasket, d.floatingShelfBasket)
        liveAudioSpectrumEnabled = value(.liveAudioSpectrumEnabled, d.liveAudioSpectrumEnabled)
        quickAIConfig = value(.quickAIConfig, d.quickAIConfig)
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
        try c.encode(
            IslandFeature.allCases.filter { !enabledFeatures.contains($0) }.map(\.rawValue), forKey: .disabledFeatures)
        try c.encode(weatherLocation, forKey: .weatherLocation)
        try c.encode(temperatureUnit, forKey: .temperatureUnit)
        try c.encode(shelfCopiesFiles, forKey: .shelfCopiesFiles)
        try c.encode(shelfRetentionDays, forKey: .shelfRetentionDays)  // writes null for "never"
        try c.encodeIfPresent(muteUntil, forKey: .muteUntil)
        try c.encode(showMenuBarIcon, forKey: .showMenuBarIcon)
        try c.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
        try c.encode(downloadsAlertsOptedIn, forKey: .downloadsAlertsOptedIn)
        try c.encode(notifiedCompetitors, forKey: .notifiedCompetitors)
        try c.encode(fullChargeThreshold, forKey: .fullChargeThreshold)
        try c.encode(bluetoothAlertsEnabled, forKey: .bluetoothAlertsEnabled)
        try c.encode(timerMascot, forKey: .timerMascot)
        try c.encode(pillVerticalOffset, forKey: .pillVerticalOffset)
        try c.encode(hideNotchBar, forKey: .hideNotchBar)
        try c.encode(useGlassCards, forKey: .useGlassCards)
        try c.encode(doubleTapOptionToToggle, forKey: .doubleTapOptionToToggle)
        try c.encode(expandedWidth, forKey: .expandedWidth)
        try c.encode(pomodoroPlan, forKey: .pomodoroPlan)
        try c.encode(hoverToPeekEnabled, forKey: .hoverToPeekEnabled)
        try c.encode(swipeGesturesEnabled, forKey: .swipeGesturesEnabled)
        try c.encode(enabledQuickTools, forKey: .enabledQuickTools)
        try c.encode(QuickToolID.normalizedOrder(quickToolOrder), forKey: .quickToolOrder)
        try c.encode(waterDropletEffect, forKey: .waterDropletEffect)
        try c.encode(dropletSensitivity, forKey: .dropletSensitivity)
        try c.encode(visualStyle, forKey: .visualStyle)
        try c.encode(surfaceMaterial, forKey: .surfaceMaterial)
        try c.encode(compactWingLyrics, forKey: .compactWingLyrics)
        try c.encode(floatingShelfBasket, forKey: .floatingShelfBasket)
        try c.encode(liveAudioSpectrumEnabled, forKey: .liveAudioSpectrumEnabled)
        try c.encode(quickAIConfig, forKey: .quickAIConfig)
    }
}
