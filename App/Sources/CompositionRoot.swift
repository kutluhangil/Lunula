import AppKit
import IslandCore
import IslandDesign
import IslandFeatures
import IslandServices
import OSLog
import SwiftUI

/// The only place concrete services are created and wired together.
@MainActor
final class CompositionRoot {
    static let shared = CompositionRoot()

    private let logger = Logger(subsystem: "com.kutluhangul.lunula", category: "app")
    private let time = SystemTime()
    private let settings = SettingsStore(defaults: .standard)
    private let launchAtLogin = LaunchAtLoginService()
    private let windows = IslandWindowManager()
    private lazy var feedback = SystemFeedbackPlayer(preferences: { [unowned self] in
        let muted = isMuted
        return (settings.settings.hapticsEnabled && !muted, settings.settings.soundsEnabled && !muted)
    })
    private lazy var statusItem = StatusItemController(menu: { [unowned self] in contextMenu() })
    private var screenService: ScreenService?
    private var islands: [UInt32: ScreenIsland] = [:]
    private var screens: [ScreenDescriptor] = []
    private var settingsWindow: SettingsWindowController?
    private var tasks: [Task<Void, Never>] = []

    func start() {
        logger.info("start")
        let screenService = ScreenService()
        self.screenService = screenService
        screens = screenService.current
        tasks.append(
            Task { [unowned self] in
                for await states in fullscreen.updates() {
                    for (id, isFullscreen) in states { islands[id]?.store.send(.fullscreenChanged(isFullscreen)) }
                }
            })
        applySettings()  // first call syncs the windows
        observeSettings()
        GlobalShortcut.install { [unowned self] in activeIsland()?.store.send(.toggleRequested) }

        tasks.append(
            Task { [unowned self] in
                for await updated in screenService.updates() {
                    screens = updated
                    syncWindows()
                    broadcast(.displayConfigurationChanged)
                }
            })
        let systemEvents = SystemEventsMonitor()
        tasks.append(
            Task { [unowned self] in
                for await event in systemEvents.events() {
                    switch event {
                    case .willSleep: broadcast(.systemWillSleep)
                    case .didWake: broadcast(.systemDidWake)
                    case .screensDidSleep, .screensDidWake: break
                    }
                }
            })
    }

    private lazy var fullscreen = FullscreenMonitor(
        screens: { [unowned self] in screens },
        frontmostPID: { NSWorkspace.shared.frontmostApplication?.processIdentifier })

    // MARK: - Windows

    private func syncWindows() {
        let controllers = windows.sync(screens: screens, mode: settings.settings.displayMode) { [unowned self] screen in
            makeIsland(for: screen)
        }
        islands = islands.filter { controllers[$0.key] != nil }
        for (id, controller) in controllers {
            guard let island = islands[id], let screen = screens.first(where: { $0.id == id }) else { continue }
            // Displays keep their id across rearrangement and resolution changes; refresh the geometry.
            island.screen = screen
            let notch = NotchGeometry.metrics(for: screen)
            if notch != island.notch {
                island.notch = notch
                controller.setContent(rootView(for: island))
            }
            island.panel.target = controller
            controller.hotZone.hotZoneView.delegate = island.router
            controller.scrollDelegate = island.router
            controller.onResignKey = { [weak island] in island?.store.send(.clickedOutside) }
            island.hotZoneRect = nil
            layoutHotZone(id)
        }
        fullscreen.refresh()
    }

    private func makeIsland(for screen: ScreenDescriptor) -> AnyView {
        let panel = PanelProxy()
        let store = IslandStore(time: time, panel: panel, feedback: feedback, speed: { [panel] in panel.speed() })
        let island = ScreenIsland(screen: screen, store: store, panel: panel)
        let router = PointerRouter(
            send: { store.send($0) }, phase: { store.state.phase },
            geometry: { [unowned island] in Self.restingGeometry(state: store.state, notch: island.notch) },
            showContextMenu: { [unowned self] point in contextMenu().popUp(positioning: nil, at: point, in: nil) })
        island.router = router
        panel.speed = { [weak router] in router?.currentSpeed ?? 0 }
        store.send(.optionsChanged(settings.settings.islandOptions))
        islands[screen.id] = island
        observeHotZone(of: island)
        return rootView(for: island)
    }

    private func rootView(for island: ScreenIsland) -> AnyView {
        AnyView(
            IslandRootView(
                store: island.store, notch: island.notch, home: { Self.homeInputs },
                onHover: { [weak router = island.router] in router?.islandHoverChanged($0) },
                openSettings: { [unowned self] in showSettings() }))
    }

    /// While closed the hot zone hugs the visible island, which widens when an activity shows in the wings.
    private func layoutHotZone(_ id: UInt32) {
        guard let island = islands[id], let controller = windows.controller(for: id) else { return }
        let rect = IslandMetrics.hotZone(
            around: Self.restingGeometry(state: island.store.state, notch: island.notch).island)
        guard rect != island.hotZoneRect else { return }
        island.hotZoneRect = rect
        controller.layout(screen: island.screen, hotZoneRect: rect)
    }

    private func observeHotZone(of island: ScreenIsland) {
        withObservationTracking {
            _ = island.store.state.layout
            _ = island.store.state.phase
        } onChange: { [weak self, weak island] in
            Task { @MainActor [weak self, weak island] in
                guard let self, let island else { return }
                layoutHotZone(island.screen.id)
                observeHotZone(of: island)
            }
        }
    }

    private static func restingGeometry(state: IslandState, notch: NotchMetrics)
        -> (island: CGRect, bubbles: [(ActivityID, CGRect)])
    {
        let request: IslandSizeRequest =
            switch state.phase {
            case .transient: .compact(wing: IslandMetrics.wingMax)
            default: state.layout.primary == nil ? .idle : .compact(wing: IslandMetrics.wingMax)
            }
        let island = IslandMetrics.islandRect(size: IslandMetrics.size(for: request, notch: notch), notch: notch)
        let bubbles = state.layout.detached.enumerated().map { index, activity in
            (activity.id, IslandMetrics.bubbleRect(index: index, primary: island, notch: notch))
        }
        return (island, bubbles)
    }

    /// Feature phases bind real inputs; until then the home page shows its quick-start tile.
    private static let homeInputs = HomeInputs(
        pendingPermission: nil, hasNowPlaying: false, hasImminentMeeting: false, hasRunningTimer: false,
        hasWeather: false, hasUpcomingEvent: false, calendarAccessUndetermined: false)

    private func activeIsland() -> ScreenIsland? {
        let mouse = NSEvent.mouseLocation
        return islands.values.first { $0.screen.frame.contains(mouse) }
            ?? islands.values.first { $0.screen.isMain } ?? islands.values.first
    }

    private func broadcast(_ event: IslandEvent) {
        for island in islands.values { island.store.send(event) }
    }

    // MARK: - Settings

    private var isMuted: Bool { (settings.settings.muteUntil ?? .distantPast) > time.now }

    private func observeSettings() {
        withObservationTracking {
            _ = settings.settings
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.applySettings()
                self?.observeSettings()
            }
        }
    }

    private var appliedSettings: IslandSettings?

    private func applySettings() {
        let current = settings.settings
        defer { appliedSettings = current }
        if appliedSettings?.displayMode != current.displayMode { syncWindows() }
        if appliedSettings?.islandOptions != current.islandOptions {
            broadcast(.optionsChanged(current.islandOptions))
        }
        statusItem.isVisible = current.showMenuBarIcon
    }

    private func contextMenu() -> NSMenu {
        ContextMenuBuilder.menu(
            isMuted: isMuted,
            actions: ContextMenuActions(
                openSettings: { [unowned self] in showSettings() },
                toggleMute: { [unowned self] in
                    let muted = isMuted
                    settings.update { $0.muteUntil = muted ? nil : time.now.addingTimeInterval(3600) }
                },
                quit: { NSApp.terminate(nil) }))
    }

    func showSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController(
                tabs: SettingsTab.baseTabs(settings: settings, launchAtLogin: launchAtLogin))
        }
        settingsWindow?.show()
    }
}

/// Per-screen island parts. The store needs a panel before the window controller exists, hence the proxy.
@MainActor private final class ScreenIsland {
    var screen: ScreenDescriptor
    var notch: NotchMetrics
    let store: IslandStore
    let panel: PanelProxy
    var router: PointerRouter!
    var hotZoneRect: CGRect?

    init(screen: ScreenDescriptor, store: IslandStore, panel: PanelProxy) {
        self.screen = screen
        notch = NotchGeometry.metrics(for: screen)
        self.store = store
        self.panel = panel
    }
}

@MainActor private final class PanelProxy: PanelControlling {
    weak var target: IslandWindowController?
    /// Pointer speed from the router, which is created after the store.
    var speed: @MainActor () -> Double = { 0 }
    func setMouseEventsIgnored(_ ignored: Bool) { target?.setMouseEventsIgnored(ignored) }
    func makeKey(_ key: Bool) { target?.makeKey(key) }
}
