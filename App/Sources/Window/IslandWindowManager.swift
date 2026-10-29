import IslandCore
import SwiftUI

/// One island (panel + hot zone) per selected screen, keyed by display id.
@MainActor final class IslandWindowManager {
    private var controllers: [UInt32: IslandWindowController] = [:]

    @discardableResult
    func sync(screens: [ScreenDescriptor], mode: DisplayMode, make: (ScreenDescriptor) -> AnyView)
        -> [UInt32: IslandWindowController]
    {
        let selected = DisplaySelection.screens(from: screens, mode: mode)
        let ids = Set(selected.map(\.id))
        for (id, controller) in controllers where !ids.contains(id) {
            controller.close()
            controllers[id] = nil
        }
        for screen in selected {
            if let existing = controllers[screen.id] {
                existing.layout(
                    screen: screen,
                    hotZoneRect: IslandMetrics.hotZone(
                        around: NotchGeometry.metrics(for: screen).rect, screenTop: screen.frame.maxY))
            } else {
                controllers[screen.id] = IslandWindowController(screen: screen, content: make(screen))
            }
        }
        return controllers
    }

    func controller(for id: UInt32) -> IslandWindowController? { controllers[id] }
}
