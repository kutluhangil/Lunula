import AppKit
import Foundation
import IslandCore
import Observation

/// Event-driven pasteboard watcher (checks on app activation and island expansion, zero background polling).
@MainActor @Observable public final class PasteboardMonitor {
    @ObservationIgnored private let store: ClipboardHistoryStore
    @ObservationIgnored private var lastChangeCount: Int
    @ObservationIgnored private var workspaceObserver: NSObjectProtocol?
    @ObservationIgnored private var activeObserver: NSObjectProtocol?

    public init(store: ClipboardHistoryStore) {
        self.store = store
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    public func start() {
        guard workspaceObserver == nil else { return }
        lastChangeCount = NSPasteboard.general.changeCount
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.checkNow() }
        }
        activeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.checkNow() }
        }
    }

    public func stop() {
        if let workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver)
        }
        if let activeObserver {
            NotificationCenter.default.removeObserver(activeObserver)
        }
        workspaceObserver = nil
        activeObserver = nil
    }

    public func checkNow() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount
        if let copied = pb.string(forType: .string) {
            store.record(copied)
        }
    }
}
