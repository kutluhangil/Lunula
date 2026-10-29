import IslandCore
import SwiftUI

/// Every feature can be turned off; features that need a permission show its state next to the toggle.
struct ActivitiesSettingsView: View {
    static let features: [IslandFeature] = [
        .nowPlaying, .timer, .calendar, .weather, .shelf, .battery, .downloads, .privacyIndicator, .customActivities,
    ]

    let settings: SettingsStore
    let permission: @MainActor (IslandFeature) -> PermissionState?
    let request: @MainActor (IslandFeature) -> Void

    var body: some View {
        Form {
            ForEach(Self.features, id: \.self) { feature in
                Section {
                    Toggle(Self.titleKey(feature), isOn: binding(feature))
                    if feature == .downloads, isOn(feature) {
                        Text("settings.activities.downloadsNote").font(.caption).foregroundStyle(.secondary)
                    }
                    if isOn(feature), let state = permission(feature) {
                        PermissionRow(
                            titleKey: "settings.activities.permission", state: state, onRequest: { request(feature) },
                            onOpenSettings: { NSWorkspace.shared.open(Self.settingsURL(feature)) })
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
    }

    private func isOn(_ feature: IslandFeature) -> Bool {
        settings.settings.enabledFeatures.contains(feature)
            && (feature != .downloads || settings.settings.downloadsAlertsOptedIn)
    }

    /// Download alerts are opt-in: turning them on here is the user's consent to watch ~/Downloads.
    private func binding(_ feature: IslandFeature) -> Binding<Bool> {
        Binding(
            get: { isOn(feature) },
            set: { on in
                settings.update {
                    if on { $0.enabledFeatures.insert(feature) } else { $0.enabledFeatures.remove(feature) }
                    if feature == .downloads { $0.downloadsAlertsOptedIn = on }
                }
            })
    }

    static func titleKey(_ feature: IslandFeature) -> LocalizedStringKey {
        LocalizedStringKey("settings.feature." + feature.rawValue)
    }

    static func settingsURL(_ feature: IslandFeature) -> URL {
        switch feature {
        case .calendar: PermissionRow.settingsURL("Privacy_Calendars")
        case .weather: PermissionRow.settingsURL("Privacy_LocationServices")
        default: PermissionRow.settingsURL("Privacy_Automation")
        }
    }
}
