import CoreGraphics
import Foundation
import IslandCore

public protocol WindowListReading: Sendable {
    func windows() -> [WindowInfo]
}

/// Reads only PID, layer, bounds and on-screen flag. Window and owner names are never read, so no Screen Recording permission is needed.
public struct CGWindowListReader: WindowListReading {
    public init() {}

    public func windows() -> [WindowInfo] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return [] }
        return list.compactMap { entry in
            guard let pid = entry[kCGWindowOwnerPID as String] as? Int32,
                let layer = entry[kCGWindowLayer as String] as? Int,
                let boundsDict = entry[kCGWindowBounds as String] as? NSDictionary,
                let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary)
            else { return nil }
            let onscreen = (entry[kCGWindowIsOnscreen as String] as? Bool) ?? false
            return WindowInfo(ownerPID: pid, layer: layer, bounds: bounds, isOnscreen: onscreen)
        }
    }
}
