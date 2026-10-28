import Foundation
import IslandCore

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

// Sample values; real device values are recorded in T9.6.
extension ScreenDescriptor {
    public static let mbp14 = ScreenDescriptor(
        id: 1, frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
        visibleFrame: CGRect(x: 0, y: 0, width: 1512, height: 950), safeAreaTop: 32,
        auxiliaryTopLeft: CGRect(x: 0, y: 950, width: 662, height: 32),
        auxiliaryTopRight: CGRect(x: 850, y: 950, width: 662, height: 32),
        menuBarHeight: 32, isBuiltIn: true, isMain: true, localizedName: "Built-in Retina Display")
    public static let external = ScreenDescriptor(
        id: 2, frame: CGRect(x: 1512, y: 0, width: 2560, height: 1440),
        visibleFrame: CGRect(x: 1512, y: 0, width: 2560, height: 1416), safeAreaTop: 0,
        auxiliaryTopLeft: nil, auxiliaryTopRight: nil, menuBarHeight: 24, isBuiltIn: false, isMain: false,
        localizedName: "LG")
}
