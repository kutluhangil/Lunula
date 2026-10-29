import AppKit
import IslandCore
import IslandCoreTestSupport
import SwiftUI
import Testing

@testable import IslandFeatures

@MainActor @Suite struct WeatherTileTests {
    @Test func symbolExistsForEveryCondition() {
        for c in WeatherCondition.allCases {
            for day in [true, false] {
                #expect(
                    NSImage(systemSymbolName: WeatherSymbol.name(c, isDaylight: day), accessibilityDescription: nil)
                        != nil, "\(c) \(day)")
            }
        }
    }

    @Test func tileRendersLongestTurkishConditionWithinTile() {
        let tile = WeatherTileView(
            snapshot: .fixture(condition: .thunderstorm), units: .init(temperature: .celsius, speed: .kilometersPerHour)
        )
        .frame(width: 160).environment(\.locale, Locale(identifier: "tr_TR"))
        let r = ImageRenderer(content: tile)
        #expect(r.cgImage?.width == Int(160 * r.scale))
    }
}
