import Foundation

// Apple SDKs (Xcode 27) no longer expose CGRect members through Foundation alone; Linux Foundation has them.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// Plain-value snapshot of an NSScreen. Coordinates are AppKit global (origin bottom-left, y up).
public struct ScreenDescriptor: Equatable, Sendable {
    public var id: UInt32
    public var frame: CGRect
    public var visibleFrame: CGRect
    public var safeAreaTop: CGFloat
    public var auxiliaryTopLeft: CGRect?
    public var auxiliaryTopRight: CGRect?
    public var menuBarHeight: CGFloat
    public var isBuiltIn: Bool
    public var isMain: Bool
    public var localizedName: String

    public init(
        id: UInt32, frame: CGRect, visibleFrame: CGRect, safeAreaTop: CGFloat,
        auxiliaryTopLeft: CGRect?, auxiliaryTopRight: CGRect?, menuBarHeight: CGFloat,
        isBuiltIn: Bool, isMain: Bool, localizedName: String
    ) {
        self.id = id
        self.frame = frame
        self.visibleFrame = visibleFrame
        self.safeAreaTop = safeAreaTop
        self.auxiliaryTopLeft = auxiliaryTopLeft
        self.auxiliaryTopRight = auxiliaryTopRight
        self.menuBarHeight = menuBarHeight
        self.isBuiltIn = isBuiltIn
        self.isMain = isMain
        self.localizedName = localizedName
    }

}
