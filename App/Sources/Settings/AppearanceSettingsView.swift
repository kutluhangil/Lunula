import IslandCore
import SwiftUI

struct AppearanceSettingsView: View {
    let settings: SettingsStore

    var body: some View {
        Form {
            Section {
                LabeledContent("settings.appearance.halo") {
                    Slider(value: binding(\.haloIntensity), in: 0...1)
                }
                Toggle("settings.appearance.haptics", isOn: binding(\.hapticsEnabled))
                Toggle("settings.appearance.sounds", isOn: binding(\.soundsEnabled))
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
    }

    private func binding<T>(_ keyPath: WritableKeyPath<IslandSettings, T>) -> Binding<T> {
        Binding(
            get: { settings.settings[keyPath: keyPath] }, set: { v in settings.update { $0[keyPath: keyPath] = v } })
    }
}
