import AppKit
import IslandCore

/// Opens the shelf when a file drag nears the top of a screen. The global monitor only fires while the mouse is
/// dragged or released, so it costs nothing at idle; no Accessibility permission is needed for mouse monitors.
@MainActor final class FileDragMonitor {
    private let screens: @MainActor () -> [ScreenDescriptor]
    private let send: @MainActor (UInt32, IslandEvent) -> Void
    private var monitor: Any?
    private var changeCountAtMouseUp = NSPasteboard(name: .drag).changeCount
    private var approached: UInt32?

    init(
        screens: @escaping @MainActor () -> [ScreenDescriptor], send: @escaping @MainActor (UInt32, IslandEvent) -> Void
    ) {
        self.screens = screens
        self.send = send
    }

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak self] event in
            let type = event.type
            MainActor.assumeIsolated { self?.handle(type) }
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    private func handle(_ type: NSEvent.EventType) {
        let pasteboard = NSPasteboard(name: .drag)
        if type == .leftMouseUp {
            changeCountAtMouseUp = pasteboard.changeCount
            leave()
            return
        }
        guard pasteboard.changeCount != changeCountAtMouseUp, pasteboard.types?.contains(.fileURL) == true else {
            return
        }
        let point = NSEvent.mouseLocation
        let target = screens().first { DragProximity.isApproaching(point: point, screenFrame: $0.frame) }?.id
        guard target != approached else { return }
        leave()
        if let target {
            approached = target
            send(target, .fileDragApproached)
        }
    }

    private func leave() {
        if let approached { send(approached, .fileDragLeft) }
        approached = nil
    }
}
