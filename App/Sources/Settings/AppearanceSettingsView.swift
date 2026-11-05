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
                LabeledContent("settings.appearance.pillOffset") {
                    Slider(value: binding(\.pillVerticalOffset), in: 0...8, step: 1)
                }
                Toggle("settings.appearance.hideNotchBar", isOn: binding(\.hideNotchBar))
                Toggle("settings.appearance.useGlassCards", isOn: binding(\.useGlassCards))
                Toggle("settings.appearance.haptics", isOn: binding(\.hapticsEnabled))
                Toggle("settings.appearance.sounds", isOn: binding(\.soundsEnabled))
            }
            Section {
                LabeledContent("settings.appearance.fullChargeThreshold") {
                    Stepper(value: binding(\.fullChargeThreshold), in: 80...100, step: 5) {
                        Text("\(settings.settings.fullChargeThreshold)%").monospacedDigit()
                    }
                }
                Picker("settings.appearance.timerMascot", selection: binding(\.timerMascot)) {
                    Text("settings.appearance.mascot.none").tag(TimerMascot.none)
                    Text("settings.appearance.mascot.hare").tag(TimerMascot.hare)
                    Text("settings.appearance.mascot.tortoise").tag(TimerMascot.tortoise)
                    Text("settings.appearance.mascot.cat").tag(TimerMascot.cat)
                    Text("settings.appearance.mascot.bird").tag(TimerMascot.bird)
                    Text("settings.appearance.mascot.flame").tag(TimerMascot.flame)
                }
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
