import AppKit
import Foundation
import IslandCore

/// Observes `.flagsChanged` modifier events (no Input Monitoring permission needed) to surface a brief Caps Lock HUD.
@MainActor public final class CapsLockMonitor: AlertProviding {
    public var onAlert: (@MainActor (TransientAlert) -> Void)?
    public var labelProvider: @MainActor (Bool) -> String = { $0 ? "Caps Lock ON" : "Caps Lock OFF" }
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var lastCapsLockState: Bool

    public init() {
        self.lastCapsLockState = NSEvent.modifierFlags.contains(.capsLock)
    }

    public func start() {
        guard globalMonitor == nil else { return }
        lastCapsLockState = NSEvent.modifierFlags.contains(.capsLock)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let isOn = event.modifierFlags.contains(.capsLock)
            Task { @MainActor [weak self] in self?.handleFlags(capsLockOn: isOn) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let isOn = event.modifierFlags.contains(.capsLock)
            Task { @MainActor [weak self] in self?.handleFlags(capsLockOn: isOn) }
            return event
        }
    }

    public func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    private func handleFlags(capsLockOn: Bool) {
        guard capsLockOn != lastCapsLockState else { return }
        lastCapsLockState = capsLockOn
        onAlert?(
            TransientAlert(
                id: UUID(), kind: .custom,
                detail: .text(
                    title: labelProvider(capsLockOn),
                    subtitle: nil,
                    symbol: capsLockOn ? "capslock.fill" : "capslock"),
                tint: capsLockOn ? .orange : .neutral,
                duration: 1.4,
                priority: .normal))
    }
}
