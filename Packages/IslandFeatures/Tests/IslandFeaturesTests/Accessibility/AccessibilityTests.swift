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

    @Test(arguments: ["tr", "en"])
    func everyLabelResolvesInTurkishAndEnglish(language: String) {
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
