import AppKit
import CoreGraphics
import IslandCore

extension ScreenDescriptor {
    @MainActor
    public init(_ screen: NSScreen, isMain: Bool) {
        let id = screen.cgDirectDisplayID ?? 0
        let top = screen.safeAreaInsets.top
        var menuBar = max(screen.frame.maxY - screen.visibleFrame.maxY, top)
        // Auto-hidden menu bar leaves no inset; fall back to the system thickness.
        if menuBar == 0 { menuBar = NSStatusBar.system.thickness }
        self.init(
            id: id, frame: screen.frame, visibleFrame: screen.visibleFrame, safeAreaTop: top,
            auxiliaryTopLeft: screen.auxiliaryTopLeftArea, auxiliaryTopRight: screen.auxiliaryTopRightArea,
            menuBarHeight: menuBar, isBuiltIn: CGDisplayIsBuiltin(id) != 0, isMain: isMain,
            localizedName: screen.localizedName)
    }
}
