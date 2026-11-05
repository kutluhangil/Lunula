import AppKit
import IslandDesign
import SwiftUI

/// Sandbox-safe Keyboard Cleaning Lock & Keystroke HUD: presents a full-screen key panel that absorbs local
/// keystrokes while wiping the keyboard, displays the pressed key HUD, and unlocks on ⌘⎋ (`Command + Escape`)
/// or after 30 seconds.
@MainActor final class KeyboardLockController {
    private var panel: KeyLockPanel?
    private var monitor: Any?
    private var timer: Timer?
    fileprivate let model = KeyboardLockModel()

    func lock(durationSeconds: Int = 30) {
        guard panel == nil, let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        model.remainingSeconds = durationSeconds
        model.lastKeystrokeLabel = "—"

        let panel = KeyLockPanel(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)
        panel.level = .screenSaver
        panel.backgroundColor = .black
        panel.isOpaque = true
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(
            rootView: KeyboardLockOverlayView(model: model, onUnlock: { [weak self] in self?.unlock() }))

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel

        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self else { return nil }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            // ⌘⎋ (Command + Escape, keyCode 53) unlocks immediately.
            if flags.contains(.command) && event.keyCode == 53 {
                Task { @MainActor [weak self] in self?.unlock() }
                return nil
            }
            if event.type == .keyDown {
                let label = Self.describeKey(event)
                Task { @MainActor [weak self] in
                    self?.model.lastKeystrokeLabel = label
                }
            }
            return nil
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.model.remainingSeconds > 1 {
                    self.model.remainingSeconds -= 1
                } else {
                    self.unlock()
                }
            }
        }
    }

    func unlock() {
        timer?.invalidate()
        timer = nil
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        panel?.orderOut(nil)
        panel?.close()
        panel = nil
    }

    private nonisolated static func describeKey(_ event: NSEvent) -> String {
        var parts: [String] = []
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }
        let chars = (event.charactersIgnoringModifiers ?? "").uppercased()
        switch event.keyCode {
        case 36: parts.append("↩")
        case 48: parts.append("⇥")
        case 49: parts.append("Space")
        case 51: parts.append("⌫")
        case 53: parts.append("⎋")
        default:
            parts.append(chars.isEmpty ? "Key \(event.keyCode)" : chars)
        }
        return parts.joined(separator: " ")
    }
}

private final class KeyLockPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor @Observable private final class KeyboardLockModel {
    var remainingSeconds: Int = 30
    var lastKeystrokeLabel: String = "—"
}

private struct KeyboardLockOverlayView: View {
    let model: KeyboardLockModel
    let onUnlock: @MainActor () -> Void

    var body: some View {
        ZStack {
            Palette.obsidian.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "keyboard.badge.ellipsis")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(Palette.signalOrange)

                Text("lock.keyboard.title")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.textPrimary)

                Text("\(model.remainingSeconds)s")
                    .font(TypeToken.numeralLarge.font)
                    .monospacedDigit()
                    .foregroundStyle(Palette.signalOrange)

                HStack(spacing: 8) {
                    Text("Keystroke HUD:")
                        .font(TypeToken.caption.font)
                        .foregroundStyle(Palette.textSecondary)
                    Text(model.lastKeystrokeLabel)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Palette.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Palette.inkPressed, in: Capsule())
                }

                Text("lock.keyboard.hint")
                    .font(TypeToken.body.font)
                    .foregroundStyle(Palette.textSecondary)

                Button(action: onUnlock) {
                    Text("lock.keyboard.unlock")
                        .font(TypeToken.body.font)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Palette.textPrimary, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(32)
            .islandCard()
        }
    }
}
