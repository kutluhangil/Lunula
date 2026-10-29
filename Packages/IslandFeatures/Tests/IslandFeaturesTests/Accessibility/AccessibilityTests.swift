import Foundation
import IslandCore
import Testing

@testable import IslandFeatures

@Suite struct AccessibilityTests {
    static var allLabels: [LocalizedStringResource] {
        [
            AccessibilityLabels.playPause(isPlaying: true), AccessibilityLabels.playPause(isPlaying: false),
            AccessibilityLabels.next, AccessibilityLabels.previous, AccessibilityLabels.seek,
            AccessibilityLabels.startTimer, AccessibilityLabels.pauseTimer, AccessibilityLabels.join,
            AccessibilityLabels.removeShelfItem, AccessibilityLabels.openSettings,
            AccessibilityLabels.island(summary: "Derleme"),
        ]
    }

    /// Every label key has a translated Turkish and English entry in the package catalog (source of truth; CI's
    /// `swift test` may copy the catalog uncompiled, so runtime lookup alone is not reliable there).
    @Test func everyLabelHasTurkishAndEnglishEntry() throws {
        let catalog = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Sources/IslandFeatures/Resources/Localizable.xcstrings")
        let json = try #require(
            try JSONSerialization.jsonObject(with: Data(contentsOf: catalog)) as? [String: Any])
        let strings = try #require(json["strings"] as? [String: [String: Any]])
        for label in Self.allLabels {
            let localizations = strings[label.key]?["localizations"] as? [String: [String: [String: String]]]
            for language in ["tr", "en"] {
                let unit = localizations?[language]?["stringUnit"]
                #expect(
                    unit?["state"] == "translated" && unit?["value"]?.isEmpty == false, "\(label.key) [\(language)]")
            }
        }
    }

    /// When the catalog is compiled into the bundle (Xcode builds), labels must also resolve at runtime.
    @Test(arguments: ["tr", "en"])
    func labelsResolveAtRuntimeWhenCompiled(language: String) {
        guard
            Bundle.module.path(
                forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: language)
                != nil
        else { return }
        for label in Self.allLabels {
            var resource = label
            resource.locale = Locale(identifier: language)
            let text = String(localized: resource)
            #expect(!text.isEmpty && text != label.key, "\(label.key) [\(language)]")
        }
    }

    @Test func textColorsMeetContrast() {
        // textPrimary #F5F5F7; textSecondary is white at 62 % over the black core.
        #expect(RGBAColor(red: 0xF5 / 255, green: 0xF5 / 255, blue: 0xF7 / 255).contrastRatio(with: .black) >= 4.5)
        #expect(RGBAColor(red: 0.62, green: 0.62, blue: 0.62).contrastRatio(with: .black) >= 4.5)
    }
}
