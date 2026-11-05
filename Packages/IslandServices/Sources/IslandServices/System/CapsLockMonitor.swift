import AppKit
import Foundation
import IslandCore

/// Observes `.flagsChanged` modifier events (no Input Monitoring permission needed) to surface a brief Caps Lock HUD
/// and detect a clean double-tap of the Option (⌥) key ("Knock to Control" double-tap-a-key mode).
@MainActor public final class CapsLockMonitor: AlertProviding {
    public var onAlert: (@MainActor (TransientAlert) -> Void)?
    public var onOptionDoubleTap: (@MainActor () -> Void)?
    public var labelProvider: @MainActor (Bool) -> String = { $0 ? "Caps Lock ON" : "Caps Lock OFF" }
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var lastCapsLockState: Bool
    private var doubleTapDetector = ModifierDoubleTapDetector()

    public init() {
        self.lastCapsLockState = NSEvent.modifierFlags.contains(.capsLock)
    }

    public func start() {
        guard globalMonitor == nil else { return }
        lastCapsLockState = NSEvent.modifierFlags.contains(.capsLock)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            Task { @MainActor [weak self] in self?.handleFlags(flags) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            Task { @MainActor [weak self] in self?.handleFlags(flags) }
            return event
        }
    }

    public func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    private func handleFlags(_ flags: NSEvent.ModifierFlags) {
        let capsLockOn = flags.contains(.capsLock)
        if capsLockOn != lastCapsLockState {
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

        let optionPressed = flags.contains(.option)
        let otherModifiers = !flags.intersection([.command, .control, .shift]).isEmpty
        if doubleTapDetector.registerFlagsChange(
            targetPressed: optionPressed, otherModifiersPressed: otherModifiers, at: Date())
        {
            onOptionDoubleTap?()
        }
    }
}
