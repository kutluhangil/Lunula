import IslandCore
import IslandServices
import SwiftUI

/// One toolbar tab of the settings window. Feature tasks append their own tabs (Integrator note).
struct SettingsTab: Identifiable {
    let id: String
    let titleKey: LocalizedStringResource
    let symbol: String
    let makeView: @MainActor () -> AnyView

    @MainActor static func baseTabs(settings: SettingsStore, launchAtLogin: LaunchAtLoginService) -> [SettingsTab] {
        [
            SettingsTab(
                id: "general", titleKey: "settings.tab.general", symbol: "gearshape",
                makeView: { AnyView(GeneralSettingsView(settings: settings, launchAtLogin: launchAtLogin)) }),
            SettingsTab(
                id: "about", titleKey: "settings.tab.about", symbol: "info.circle",
                makeView: { AnyView(AboutSettingsView()) }),
        ]
    }
}
