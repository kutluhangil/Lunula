import IslandCore
import IslandServices
import KeyboardShortcuts
import SwiftUI

struct GeneralSettingsView: View {
    let settings: SettingsStore
    let launchAtLogin: LaunchAtLoginService
    @State private var loginError = false

    var body: some View {
        Form {
            Section {
                Toggle(
                    "settings.general.launchAtLogin",
                    isOn: Binding(
                        get: { launchAtLogin.isEnabled },
                        set: { on in
                            do { try launchAtLogin.setEnabled(on) } catch { loginError = true }
                        }))
                if launchAtLogin.requiresApproval || loginError {
                    Text("settings.general.loginApproval").font(.caption).foregroundStyle(.secondary)
                    Button("settings.general.openLoginItems") { launchAtLogin.openSystemSettings() }
                }
            }
            Section {
                Picker("settings.general.displayMode", selection: binding(\.displayMode)) {
                    Text("settings.displayMode.notchedOnly").tag(DisplayMode.notchedOnly)
                    Text("settings.displayMode.allDisplays").tag(DisplayMode.allDisplays)
                    Text("settings.displayMode.mainDisplay").tag(DisplayMode.mainDisplay)
                }
                Toggle("settings.general.hideInFullscreen", isOn: binding(\.hideInFullscreen))
                Toggle("settings.general.criticalAlertsInFullscreen", isOn: binding(\.criticalAlertsInFullscreen))
                    .disabled(!settings.settings.hideInFullscreen)
            }
            Section {
                KeyboardShortcuts.Recorder("shortcut.toggleIsland", name: .toggleIsland)
                Toggle("settings.general.showMenuBarIcon", isOn: binding(\.showMenuBarIcon))
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .onAppear { launchAtLogin.refresh() }
    }

    private func binding<T>(_ keyPath: WritableKeyPath<IslandSettings, T>) -> Binding<T> {
        Binding(
            get: { settings.settings[keyPath: keyPath] },
            set: { value in settings.update { $0[keyPath: keyPath] = value } })
    }
}
