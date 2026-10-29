import Foundation
import IOKit.ps
import IslandCore
import Testing

@testable import IslandServices

@Suite struct PowerSourceParserTests {
    @Test func parsesBatteryDescription() {
        let d: [String: Any] = [
            kIOPSCurrentCapacityKey: 54, kIOPSMaxCapacityKey: 100, kIOPSIsChargingKey: true,
            kIOPSPowerSourceStateKey: kIOPSACPowerValue,
        ]
        #expect(
            PowerSourceParser.snapshot(from: d, providingSource: kIOPMACPowerKey, lowPowerMode: false)
                == BatterySnapshot(
                    level: 54, isCharging: true, isPluggedIn: true, isCharged: false, isLowPowerMode: false,
                    hasBattery: true))
    }
}
