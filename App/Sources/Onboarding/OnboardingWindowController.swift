import AppKit
import IslandCore
import IslandServices
import SwiftUI

@MainActor final class OnboardingWindowController: NSWindowController {
    private let settings: SettingsStore
    private let launchAtLoginService: LaunchAtLoginService
    private let onFinish: () -> Void

    static func shouldShow(_ settings: IslandSettings) -> Bool { !settings.hasCompletedOnboarding }

    init(settings: SettingsStore, launchAtLogin: LaunchAtLoginService, onFinish: @escaping () -> Void) {
        self.settings = settings
        launchAtLoginService = launchAtLogin
        self.onFinish = onFinish
        let window = NSWindow(
            contentRect: .zero, styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: true)
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.contentViewController = NSHostingController(
            rootView: OnboardingView { [weak self] in self?.finish(launchAtLogin: $0) })
        window.center()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func show() {
        NSApp.activate()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    /// Login item registers only if the user turned the switch on (App Review 2.4.5(iii)).
    func finish(launchAtLogin: Bool) {
        if launchAtLogin { try? launchAtLoginService.setEnabled(true) }
        settings.update { $0.hasCompletedOnboarding = true }
        window?.close()
        onFinish()
    }
}
