import SwiftUI

struct AboutSettingsView: View {
    /// Third-party notices; T6.3 appends the Open-Meteo attribution.
    static let attributions: [(name: String, license: String)] = [("KeyboardShortcuts", "MIT")]

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("settings.about.version", value: version)
            }
            Section("settings.about.licenses") {
                ForEach(Self.attributions, id: \.name) { LabeledContent($0.name, value: $0.license) }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
    }
}
