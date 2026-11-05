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
                    if feature == .weather, isOn(feature) {
                        Picker("settings.weather.unit", selection: valueBinding(\.temperatureUnit)) {
                            Text("settings.weather.unit.system").tag(TemperatureUnitPreference.system)
                            Text(verbatim: "°C").tag(TemperatureUnitPreference.celsius)
                            Text(verbatim: "°F").tag(TemperatureUnitPreference.fahrenheit)
                        }
                    }
                    if feature == .shelf, isOn(feature) {
                        Toggle("settings.shelf.copies", isOn: valueBinding(\.shelfCopiesFiles))
                        Picker("settings.shelf.retention", selection: valueBinding(\.shelfRetentionDays)) {
                            Text("settings.shelf.retention.1").tag(Int?.some(1))
                            Text("settings.shelf.retention.7").tag(Int?.some(7))
                            Text("settings.shelf.retention.30").tag(Int?.some(30))
                            Text("settings.shelf.retention.never").tag(Int?.none)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
    }

    private func valueBinding<T>(_ keyPath: WritableKeyPath<IslandSettings, T>) -> Binding<T> {
        Binding(
            get: { settings.settings[keyPath: keyPath] },
            set: { value in settings.update { $0[keyPath: keyPath] = value } })
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
