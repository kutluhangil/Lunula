import AppKit
import IslandCore
import IslandDesign
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
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 320),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(Palette.basalt)
        window.isReleasedWhenClosed = false
        super.init(window: window)
        let current = settings.settings
        window.contentViewController = NSHostingController(
            rootView: OnboardingView(
                initialStyle: current.visualStyle,
                initialMaterial: current.surfaceMaterial
            ) { [weak self] launch, style, material in
                self?.finish(launchAtLogin: launch, visualStyle: style, surfaceMaterial: material)
            }
        )
        window.setContentSize(NSSize(width: 420, height: 320))
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
    func finish(
        launchAtLogin: Bool,
        visualStyle: IslandVisualStyle = .lunula,
        surfaceMaterial: IslandSurfaceMaterial = .obsidian
    ) {
        if launchAtLogin { try? launchAtLoginService.setEnabled(true) }
        settings.update {
            $0.visualStyle = visualStyle
            $0.surfaceMaterial = surfaceMaterial
            $0.hasCompletedOnboarding = true
        }
        window?.close()
        onFinish()
    }
}
