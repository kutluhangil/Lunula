import AppKit
import IslandCore
import SwiftUI

@MainActor final class IslandWindowController {
    let screenID: UInt32
    let panel: IslandPanel
    let hotZone: HotZonePanel

    init(screen: ScreenDescriptor, content: AnyView) {
        screenID = screen.id
        let notch = NotchGeometry.metrics(for: screen)
        let frame = IslandMetrics.panelFrame(notch: notch, screen: screen)
        panel = IslandPanel(contentRect: frame)
        hotZone = HotZonePanel(contentRect: IslandMetrics.hotZone(around: notch.rect))

        // A bare NSHostingView contentView collapses the panel to its (empty) content size; keep a fixed container.
        let container = NSView(frame: NSRect(origin: .zero, size: frame.size))
        let host = NSHostingView(rootView: content)
        host.sizingOptions = []
        host.frame = container.bounds
        host.autoresizingMask = [.width, .height]
        container.addSubview(host)
        panel.contentView = container

        layout(screen: screen, hotZoneRect: IslandMetrics.hotZone(around: notch.rect))
        hotZone.orderFrontRegardless()
        panel.orderFrontRegardless()
    }

    func layout(screen: ScreenDescriptor, hotZoneRect: CGRect) {
        let notch = NotchGeometry.metrics(for: screen)
        panel.setFrame(IslandMetrics.panelFrame(notch: notch, screen: screen), display: false)
        hotZone.setFrame(hotZoneRect, display: false)
        if panel.isVisible { hotZone.order(.below, relativeTo: panel.windowNumber) }
    }

    func close() {
        hotZone.close()
        panel.close()
    }
}

extension IslandWindowController: PanelControlling {
    func setMouseEventsIgnored(_ ignored: Bool) { panel.ignoresMouseEvents = ignored }

    func makeKey(_ key: Bool) {
        if key {
            panel.allowsKey = true
            NSApp.activate()
            panel.makeKey()
        } else {
            panel.allowsKey = false
            panel.resignKey()
        }
    }
}
