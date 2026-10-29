import AppKit
import IslandCore
import IslandCoreTestSupport
import SwiftUI
import Testing

@testable import IslandFeatures

@Suite struct AlertPresentationTests {
    @Test(arguments: [
        (5, "battery.0percent"), (30, "battery.25percent"), (60, "battery.50percent"), (80, "battery.75percent"),
        (100, "battery.100percent"),
    ])
    func batterySymbolMatchesLevel(level: Int, expected: String) {
        #expect(BatterySymbol.name(level: level, charging: false) == expected)
    }

    @Test func chargingUsesBoltSymbol() {
        #expect(BatterySymbol.name(level: 40, charging: true) == "battery.100percent.bolt")
    }

    @Test func everyAlertKindHasPresentation() {
        for kind in AlertKind.allCases {
            let p = AlertPresentations.make(.fixture(kind: kind))
            #expect(
                !p.symbol.isEmpty && NSImage(systemSymbolName: p.symbol, accessibilityDescription: nil) != nil,
                "\(kind)")
        }
    }

    @MainActor @Test func alertViewRendersForEveryKind() {
        for kind in AlertKind.allCases {
            #expect(ImageRenderer(content: TransientAlertView(alert: .fixture(kind: kind))).cgImage != nil)
        }
    }
}
