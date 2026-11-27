import IslandCore
import IslandServices
import SwiftUI

public enum SettingsTabID: String, CaseIterable, Identifiable, Sendable {
    case general = "general"
    case appearance = "appearance"
    case activities = "activities"
    case tools = "tools"
    case about = "about"

    public var id: String { rawValue }

    public var titleKey: LocalizedStringResource {
        switch self {
        case .general: "settings.tab.general"
        case .appearance: "settings.tab.appearance"
        case .activities: "settings.tab.activities"
        case .tools: "settings.tab.tools"
        case .about: "settings.tab.about"
        }
    }

    public var shortTitle: String {
        String(localized: titleKey)
    }

    public var fullTitle: String {
        switch self {
        case .general: String(localized: "settings.tab.full.general")
        case .appearance: String(localized: "settings.tab.full.appearance")
        case .activities: String(localized: "settings.tab.full.activities")
        case .tools: String(localized: "settings.tab.full.tools")
        case .about: String(localized: "settings.tab.full.about")
        }
    }

    public var symbol: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "paintbrush"
        case .activities: "square.stack.3d.up"
        case .tools: "sparkles"
        case .about: "info.circle"
        }
    }
}

/// One toolbar tab of the settings window.
public struct SettingsTab: Identifiable {
    public let id: String
    public let titleKey: LocalizedStringResource
    public let symbol: String
    public let makeView: @MainActor () -> AnyView

    public init(
        id: String, titleKey: LocalizedStringResource, symbol: String, makeView: @escaping @MainActor () -> AnyView
    ) {
        self.id = id
        self.titleKey = titleKey
        self.symbol = symbol
        self.makeView = makeView
    }

    @MainActor public static func baseTabs(settings: SettingsStore, launchAtLogin: LaunchAtLoginService)
        -> [SettingsTab]
    {
        [
            SettingsTab(
                id: SettingsTabID.general.rawValue,
                titleKey: SettingsTabID.general.titleKey,
                symbol: SettingsTabID.general.symbol,
                makeView: { AnyView(GeneralSettingsView(settings: settings, launchAtLogin: launchAtLogin)) }
            ),
            SettingsTab(
                id: SettingsTabID.about.rawValue,
                titleKey: SettingsTabID.about.titleKey,
                symbol: SettingsTabID.about.symbol,
                makeView: { AnyView(AboutSettingsView()) }
            ),
        ]
    }

    @MainActor public static func allTabs(
        settings: SettingsStore,
        launchAtLogin: LaunchAtLoginService,
        permission: @escaping @MainActor (IslandFeature) -> PermissionState? = { _ in nil },
        request: @escaping @MainActor (IslandFeature) -> Void = { _ in },
        searchWeatherCity: @escaping @MainActor (String) async -> [GeoPlace] = { _ in [] },
        hasAIKey: @escaping @MainActor (QuickAIProvider) -> Bool = { _ in false },
        saveAIKey: @escaping @MainActor (String, QuickAIProvider) -> Void = { _, _ in },
        clearAIKey: @escaping @MainActor (QuickAIProvider) -> Void = { _ in },
        extraPermission: @escaping @MainActor (ExtraPermissionKind) -> PermissionState = { _ in .notRequested },
        requestExtraPermission: @escaping @MainActor (ExtraPermissionKind) -> Void = { _ in },
        ollamaModels: @escaping @MainActor () -> [String] = { [] },
        refreshOllamaModels: @escaping @MainActor (String) async -> [String] = { _ in [] },
        testAIConnection: @escaping @MainActor (QuickAIConfig) async -> (ok: Bool, message: String) = { _ in
            (false, "")
        },
        resetDefaults: (@MainActor () -> Void)? = nil
    ) -> [SettingsTab] {
        [
            SettingsTab(
                id: SettingsTabID.general.rawValue,
                titleKey: SettingsTabID.general.titleKey,
                symbol: SettingsTabID.general.symbol,
                makeView: {
                    AnyView(
                        GeneralSettingsView(
                            settings: settings,
                            launchAtLogin: launchAtLogin,
                            onResetDefaults: resetDefaults.map { action in
                                { MainActor.assumeIsolated { action() } }
                            }
                        )
                    )
                }
            ),
            SettingsTab(
                id: SettingsTabID.appearance.rawValue,
                titleKey: SettingsTabID.appearance.titleKey,
                symbol: SettingsTabID.appearance.symbol,
                makeView: { AnyView(AppearanceSettingsView(settings: settings)) }
            ),
            SettingsTab(
                id: SettingsTabID.activities.rawValue,
                titleKey: SettingsTabID.activities.titleKey,
                symbol: SettingsTabID.activities.symbol,
                makeView: {
                    AnyView(
                        ActivitiesSettingsView(
                            settings: settings,
                            permission: permission,
                            request: request,
                            searchWeatherCity: searchWeatherCity,
                            extraPermission: extraPermission,
                            requestExtraPermission: requestExtraPermission
                        )
                    )
                }
            ),
            SettingsTab(
                id: SettingsTabID.tools.rawValue,
                titleKey: SettingsTabID.tools.titleKey,
                symbol: SettingsTabID.tools.symbol,
                makeView: {
                    AnyView(
                        ToolsSettingsView(
                            settings: settings,
                            hasAIKey: hasAIKey,
                            saveAIKey: saveAIKey,
                            clearAIKey: clearAIKey,
                            ollamaModels: ollamaModels,
                            refreshOllamaModels: refreshOllamaModels,
                            testAIConnection: testAIConnection
                        )
                    )
                }
            ),
            SettingsTab(
                id: SettingsTabID.about.rawValue,
                titleKey: SettingsTabID.about.titleKey,
                symbol: SettingsTabID.about.symbol,
                makeView: { AnyView(AboutSettingsView()) }
            ),
        ]
    }
}
