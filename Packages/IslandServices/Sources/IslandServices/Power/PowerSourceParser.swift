import Foundation
import IOKit.ps
import IslandCore

public enum PowerSourceParser {
    /// `description` is one IOPSGetPowerSourceDescription dictionary; an empty one means no internal battery.
    public static func snapshot(from description: [String: Any], providingSource: String, lowPowerMode: Bool)
        -> BatterySnapshot
    {
        guard let current = description[kIOPSCurrentCapacityKey] as? Int else {
            return BatterySnapshot(
                level: 0, isCharging: false, isPluggedIn: providingSource == kIOPMACPowerKey, isCharged: false,
                isLowPowerMode: lowPowerMode, hasBattery: false)
        }
        let max = description[kIOPSMaxCapacityKey] as? Int ?? 100
        let state = description[kIOPSPowerSourceStateKey] as? String
        return BatterySnapshot(
            level: max > 0 ? Int((Double(current) / Double(max) * 100).rounded()) : current,
            isCharging: description[kIOPSIsChargingKey] as? Bool ?? false,
            isPluggedIn: state.map { $0 == kIOPSACPowerValue } ?? (providingSource == kIOPMACPowerKey),
            isCharged: description["Is Charged"] as? Bool ?? false, isLowPowerMode: lowPowerMode, hasBattery: true)
    }
}
