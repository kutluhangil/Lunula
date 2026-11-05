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

    public var shortTitle: String {
        switch self {
        case .general: "Genel"
        case .appearance: "Görünüm"
        case .activities: "Etkinlikler"
        case .tools: "Araçlar"
        case .about: "Hakkında"
        }
    }

    public var fullTitle: String {
        switch self {
        case .general: "Genel"
        case .appearance: "Görünüm ve Hâle"
        case .activities: "Etkinlikler ve İzinler"
        case .tools: "Araçlar ve Otomasyon"
        case .about: "Hakkında"
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
                titleKey: "settings.tab.general",
                symbol: SettingsTabID.general.symbol,
                makeView: { AnyView(GeneralSettingsView(settings: settings, launchAtLogin: launchAtLogin)) }
            ),
            SettingsTab(
                id: SettingsTabID.about.rawValue,
                titleKey: "settings.tab.about",
                symbol: SettingsTabID.about.symbol,
                makeView: { AnyView(AboutSettingsView()) }
            ),
        ]
    }

    @MainActor public static func allTabs(
        settings: SettingsStore,
        launchAtLogin: LaunchAtLoginService,
        permission: @escaping @MainActor (IslandFeature) -> PermissionState? = { _ in nil },
        request: @escaping @MainActor (IslandFeature) -> Void = { _ in }
    ) -> [SettingsTab] {
        [
            SettingsTab(
                id: SettingsTabID.general.rawValue,
                titleKey: "settings.tab.general",
                symbol: SettingsTabID.general.symbol,
                makeView: { AnyView(GeneralSettingsView(settings: settings, launchAtLogin: launchAtLogin)) }
            ),
            SettingsTab(
                id: SettingsTabID.appearance.rawValue,
                titleKey: "settings.tab.appearance",
                symbol: SettingsTabID.appearance.symbol,
                makeView: { AnyView(AppearanceSettingsView(settings: settings)) }
            ),
            SettingsTab(
                id: SettingsTabID.activities.rawValue,
                titleKey: "settings.tab.activities",
                symbol: SettingsTabID.activities.symbol,
                makeView: {
                    AnyView(ActivitiesSettingsView(settings: settings, permission: permission, request: request))
                }
            ),
            SettingsTab(
                id: SettingsTabID.tools.rawValue,
                titleKey: "settings.tab.tools",
                symbol: SettingsTabID.tools.symbol,
                makeView: { AnyView(ToolsSettingsView(settings: settings)) }
            ),
            SettingsTab(
                id: SettingsTabID.about.rawValue,
                titleKey: "settings.tab.about",
                symbol: SettingsTabID.about.symbol,
                makeView: { AnyView(AboutSettingsView()) }
            ),
        ]
    }
}
