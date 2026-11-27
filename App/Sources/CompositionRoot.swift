import AppIntents
import AppKit
import CoreLocation
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

    let logger = Logger(subsystem: "com.kutluhangul.lunula", category: "app")
    let time = SystemTime()
    let settings = SettingsStore(defaults: .standard)
    let launchAtLogin = LaunchAtLoginService()
    let windows = IslandWindowManager()
    lazy var hub = ActivityHub(time: time, settings: settings)
    lazy var timer = TimerController(
        time: time, defaults: .standard, planProvider: { [unowned self] in settings.settings.pomodoroPlan })
    lazy var nowPlaying: NowPlayingCoordinator = {
        let runner = ScriptRunner()
        var sources: [NowPlayingSource] = [MusicSource(runner: runner)]
        #if LUNULA_SPOTIFY
            let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            sources.append(SpotifySource(runner: runner, cacheDirectory: caches.appendingPathComponent("Artwork")))
        #endif
        return NowPlayingCoordinator(
            sources: sources, time: time, accents: ArtworkAccentStore(), permissions: AutomationPermissionChecker())
    }()
    var artworkImage: (key: String, image: NSImage)?
    lazy var calendar = CalendarService(reader: EventKitReader(), time: time)
    lazy var shelf = ShelfStore(
        directory: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Shelf"),
        bookmarks: SecurityScopedBookmarkCoding(), time: time, settings: settings)
    lazy var fileDrags = FileDragMonitor(
        screens: { [unowned self] in islands.values.map(\.screen) },
        send: { [unowned self] id, event in islands[id]?.store.send(event) })
    var shelfIcons: [UUID: NSImage] = [:]
    let power = PowerMonitor()
    lazy var keepAwake = KeepAwakeService(time: time)
    lazy var audioDevices = AudioDeviceService()
    lazy var quickNotes = QuickNotesStore(defaults: .standard, time: time)
    lazy var clipboardStore = ClipboardHistoryStore(defaults: .standard, time: time)
    lazy var pasteboardMonitor = PasteboardMonitor(store: clipboardStore)
    lazy var teleprompter = TeleprompterStore(defaults: .standard)
    lazy var appLauncher = AppLauncherStore(defaults: .standard)
    lazy var remindersStore = QuickRemindersStore(defaults: .standard, time: time)
    lazy var appleReminders = RemindersService(reader: EventKitReminderReader())
    lazy var stocksStore = StocksWatchlistStore(defaults: .standard)
    lazy var stocksService = StocksService(store: stocksStore)
    lazy var aiUsageStore = AIUsageStore(defaults: .standard, time: time)
    lazy var focusHistory = FocusHistoryStore(defaults: .standard)
    lazy var systemStats = SystemStatsService()
    lazy var externalDrives = ExternalDriveMonitor()
    lazy var capsLock = CapsLockMonitor()
    lazy var keyboardLock = KeyboardLockController()
    lazy var lyrics = LyricsService()
    lazy var quickAI = QuickAIService()
    lazy var audioSpectrum = AudioSpectrumService(time: time)
    lazy var cameraMirror = CameraMirrorService()
    lazy var screenRecorder = ScreenRecorderService()
    lazy var regionSelector = ScreenRegionSelector()
    lazy var shelfBasket = FloatingShelfBasketController(
        title: String(localized: "shelf.basket.title"),
        subtitle: String(localized: "shelf.basket.subtitle"),
        airDropLabel: String(localized: "shelf.airdrop"),
        onDropURLs: { [unowned self] urls in
            shelfActions.add(urls)
        },
        onAirDropURLs: { urls in
            NSSharingService(named: .sendViaAirDrop)?.perform(withItems: urls)
        })
    lazy var downloads = DownloadsWatcher()
    lazy var deviceUsage = DeviceUsageMonitor(reader: SystemDeviceUsageReader())
    lazy var custom = CustomActivityController(time: time)
    lazy var router = URLRouter(
        custom: custom, timer: timer,
        aiUsage: aiUsageStore,
        onAgentApprovalRequested: { [unowned self] req in
            feedback.play(.alignment)
            broadcast(
                .alertRaised(
                    TransientAlert(
                        id: UUID(), kind: .custom,
                        detail: .text(
                            title: req.agentName,
                            subtitle: req.commandSummary,
                            symbol: "checkmark.shield.fill"),
                        tint: .orange, duration: 4.0, priority: .critical)))
        },
        onBrowserMediaUpdate: { [unowned self] update in
            nowPlaying.updateBrowserMedia(update)
        },
        toggle: { [unowned self] in activeIsland()?.store.send(.toggleRequested) },
        time: time)
    lazy var weather = WeatherService(
        provider: OpenMeteoProvider(),
        cache: WeatherCache(
            fileURL: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("weather.json")),
        location: LocationService(), settings: settings, time: time)
    lazy var feedback = SystemFeedbackPlayer(preferences: { [unowned self] in
        let muted = isMuted
        return (settings.settings.hapticsEnabled && !muted, settings.settings.soundsEnabled && !muted)
    })
    lazy var statusItem = StatusItemController(menu: { [unowned self] in contextMenu() })
    var screenService: ScreenService?
    var islands: [UInt32: ScreenIsland] = [:]
    var screens: [ScreenDescriptor] = []
    var settingsWindow: SettingsWindowController?
    var onboarding: OnboardingWindowController?
    var appliedSettings: IslandSettings?
    lazy var competing = CompetingAppNotice(settings: settings)
    var tasks: [Task<Void, Never>] = []

    lazy var fullscreen = FullscreenMonitor(
        screens: { [unowned self] in screens },
        frontmostPID: { NSWorkspace.shared.frontmostApplication?.processIdentifier })

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
        hub.onLayoutChange = { [unowned self] layout in
            lyrics.update(for: nowPlaying.snapshot)
            syncAudioSpectrum()
            broadcast(.activitiesChanged(layout))
        }
        fileDrags.onDragSessionChange = { [unowned self] isDragging, point in
            shelfBasket.update(
                isDragging: isDragging,
                mouse: point,
                screens: screens,
                enabled: settings.settings.enabledFeatures.contains(.shelf) && settings.settings.floatingShelfBasket,
                surfaceMaterial: settings.settings.surfaceMaterial,
                shelfItemCount: shelf.items.count)
        }
        hub.onAlert = { [unowned self] alert in
            broadcast(.alertRaised(alert))
        }
        timer.onFocusCompleted = { [unowned self] minutes in
            focusHistory.recordCompletedMinutes(minutes, on: time.now)
        }
        power.fullChargeThreshold = { [unowned self] in settings.settings.fullChargeThreshold }
        hub.register(timer, feature: .timer)
        hub.register(alerts: timer, feature: .timer)
        hub.register(nowPlaying, feature: .nowPlaying)
        hub.register(alerts: nowPlaying, feature: .nowPlaying)
        if settings.settings.enabledFeatures.contains(.nowPlaying) { nowPlaying.start() }
        if settings.settings.enabledFeatures.contains(.shelf) {
            shelf.cleanUp()
            fileDrags.start()
        }
        if settings.settings.enabledFeatures.contains(.privacyIndicator) { deviceUsage.start() }
        hub.register(custom, feature: .customActivities)
        // Main-actor classes are Sendable; the dependency autoclosures capture the instances, not `self`.
        let (custom, timer) = (custom, timer)
        let toggler = IslandToggler { [unowned self] in activeIsland()?.store.send(.toggleRequested) }
        AppDependencyManager.shared.add(dependency: custom)
        AppDependencyManager.shared.add(dependency: timer)
        AppDependencyManager.shared.add(dependency: toggler)
        hub.register(alerts: downloads, feature: .downloads)
        // Download alerts start only after the user turns them on in Settings (T9.2): watching ~/Downloads can
        // raise a privacy prompt, and prompts must never come unasked at launch.
        if settings.settings.enabledFeatures.contains(.downloads), settings.settings.downloadsAlertsOptedIn {
            downloads.start()
        }
        hub.register(alerts: power, feature: .battery)
        audioDevices.connectedSubtitle = String(localized: "alert.device.connected")
        hub.register(alerts: audioDevices, feature: .battery)
        if settings.settings.enabledFeatures.contains(.battery) {
            power.start()
            if settings.settings.bluetoothAlertsEnabled { audioDevices.start() }
        }
        hub.register(calendar, feature: .calendar)
        if settings.settings.enabledFeatures.contains(.calendar) { calendar.start() }
        appleReminders.start()
        hub.register(alerts: competing, feature: .customActivities)
        hub.register(alerts: externalDrives, feature: .customActivities)
        if settings.settings.enabledFeatures.contains(.customActivities) {
            competing.start()
            externalDrives.start()
        }
        capsLock.labelProvider = { isOn in
            String(localized: isOn ? "alert.capsLockOn" : "alert.capsLockOff")
        }
        capsLock.onOptionDoubleTap = { [unowned self] in
            guard settings.settings.doubleTapOptionToToggle else { return }
            activeIsland()?.store.send(.toggleRequested)
        }
        hub.register(alerts: capsLock, feature: .customActivities)
        if settings.settings.enabledFeatures.contains(.customActivities)
            || settings.settings.doubleTapOptionToToggle
        {
            capsLock.start()
        }
        pasteboardMonitor.start()
        observePrivacyCallActivity()
        applySettings()  // first call syncs the windows
        if OnboardingWindowController.shouldShow(settings.settings) {
            onboarding = OnboardingWindowController(
                settings: settings, launchAtLogin: launchAtLogin, onFinish: { [unowned self] in onboarding = nil })
            onboarding?.show()
        }
        timer.restore()
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

    func handle(_ url: URL) {
        Signposts.island.emitEvent("url")
        router.handle(url)
    }

    // MARK: - Windows & Droplet Physics

    func syncWindows() {
        let signpost = Signposts.island.beginInterval("syncWindows")
        defer { Signposts.island.endInterval("syncWindows", signpost) }
        let controllers = windows.sync(screens: screens, mode: settings.settings.displayMode) { [unowned self] screen in
            makeIsland(for: screen)
        }
        islands = islands.filter { controllers[$0.key] != nil }
        for (id, controller) in controllers {
            guard let island = islands[id], let screen = screens.first(where: { $0.id == id }) else { continue }
            island.screen = screen
            let notch = NotchGeometry.metrics(for: screen)
            if notch != island.notch {
                island.notch = notch
                controller.setContent(rootView(for: island))
            }
            island.panel.target = controller
            controller.hotZone.hotZoneView.delegate = island.router
            controller.scrollDelegate = island.router
            controller.container.hoverRegion = { [unowned self, unowned island] in
                IslandRootView.hoverRegion(
                    state: island.store.state, notch: island.notch,
                    expandedWidth: CGFloat(settings.settings.expandedWidth))
            }
            controller.container.onHoverChange = { [weak router = island.router] in router?.islandHoverChanged($0) }
            controller.container.onPointerMove = { [weak self, weak island] point, velocity in
                guard let self, let island else { return }
                updateDroplet(for: island, localPoint: point, velocity: velocity)
            }
            controller.onResignKey = { [weak island] in island?.store.send(.clickedOutside) }
            controller.setNotchBackdropVisible(
                settings.settings.hideNotchBar && island.store.state.phase != .hidden)
            island.hotZoneRect = nil
            layoutHotZone(id)
        }
        fullscreen.refresh()
    }

    private func makeIsland(for screen: ScreenDescriptor) -> AnyView {
        let panel = PanelProxy()
        let screenFeedback = ScreenFeedback(
            base: feedback,
            playsSounds: { [unowned self] in
                screen.id == (screens.first(where: \.isMain) ?? screens.first)?.id
            })
        let store = IslandStore(time: time, panel: panel, feedback: screenFeedback, speed: { [panel] in panel.speed() })
        let island = ScreenIsland(screen: screen, store: store, panel: panel, feedback: screenFeedback)
        let router = PointerRouter(
            send: { store.send($0) }, phase: { store.state.phase },
            geometry: { [unowned island] in Self.restingGeometry(state: store.state, notch: island.notch) },
            showContextMenu: { [unowned self] point in contextMenu().popUp(positioning: nil, at: point, in: nil) })
        router.onHotZonePointerChanged = { [weak self, weak island] screenPoint, velocity in
            guard let self, let island else { return }
            guard let screenPoint else {
                updateDroplet(for: island, localPoint: nil, velocity: .zero)
                return
            }
            let panelFrame =
                windows.controller(for: island.screen.id)?.panel.frame
                ?? IslandMetrics.panelFrame(notch: island.notch, screen: island.screen)
            let localPoint = CGPoint(x: screenPoint.x - panelFrame.minX, y: panelFrame.maxY - screenPoint.y)
            let localVelocity = CGSize(width: velocity.width, height: -velocity.height)
            updateDroplet(for: island, localPoint: localPoint, velocity: localVelocity)
        }
        island.router = router
        panel.speed = { [weak router] in router?.currentSpeed ?? 0 }
        store.send(.optionsChanged(settings.settings.islandOptions))
        store.send(.activitiesChanged(hub.layout))
        islands[screen.id] = island
        observeHotZone(of: island)
        return rootView(for: island)
    }

    private func rootView(for island: ScreenIsland) -> AnyView {
        AnyView(
            IslandRootView(
                store: island.store, notch: island.notch, home: { [unowned self] in homeInputs },
                openSettings: { [unowned self] in showSettings() }
            )
            .environment(\.timerActions, timerActions)
            .environment(\.nowPlayingActions, nowPlayingActions)
            .environment(\.weatherInfo, WeatherInfo(current: { [unowned self] in weatherForHome }))
            .environment(\.shelfActions, shelfActions)
            .environment(\.haloIntensity, HaloIntensity(current: { [unowned self] in settings.settings.haloIntensity }))
            .environment(\.privacyInfo, PrivacyInfo(current: { [unowned self] in deviceUsage.privacy }))
            .environment(\.quickTools, makeQuickToolsActions(for: island))
            .environment(
                \.calendarActions,
                CalendarActions(
                    join: { NSWorkspace.shared.open($0) },
                    requestAccess: { [unowned self] in Task { await calendar.requestAccess() } },
                    nextEvent: { [unowned self] in calendar.nextEvent },
                    upcomingToday: { [unowned self] in calendar.upcomingToday },
                    allDayToday: { [unowned self] in calendar.allDayToday })
            )
            .environment(
                \.alertActions,
                AlertActions(
                    revealInFinder: { NSWorkspace.shared.activateFileViewerSelecting([$0]) },
                    addToShelf: { [unowned self] url in shelfActions.add([url]) })))
    }

    private func layoutHotZone(_ id: UInt32) {
        guard let island = islands[id], let controller = windows.controller(for: id) else { return }
        let rect = IslandMetrics.hotZone(
            around: Self.restingGeometry(state: island.store.state, notch: island.notch).island,
            screenTop: island.screen.frame.maxY)
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
                Signposts.island.emitEvent("phase")
                layoutHotZone(island.screen.id)
                windows.controller(for: island.screen.id)?.setNotchBackdropVisible(
                    settings.settings.hideNotchBar && island.store.state.phase != .hidden)
                let anyOpen = islands.values.contains { $0.store.state.phase.isOpen }
                nowPlaying.setExpanded(anyOpen)
                if !anyOpen { cameraMirror.stop() }
                syncAudioSpectrum()
                if anyOpen { pasteboardMonitor.checkNow() }
                if island.store.state.phase == .expanded(.home), settings.settings.enabledFeatures.contains(.weather) {
                    Task { await weather.islandBecameVisible() }
                }
                observeHotZone(of: island)
            }
        }
    }

    private static func restingGeometry(state: IslandState, notch: NotchMetrics)
        -> (island: CGRect, bubbles: [(ActivityID, CGRect)])
    {
        let request: IslandSizeRequest =
            switch state.phase {
            case .transient(let alert):
                switch alert.kind {
                case .downloadFinished:
                    if case .file = alert.detail {
                        .downloadAlert
                    } else {
                        .compact(wing: IslandMetrics.wingMax)
                    }
                case .charging, .unplugged, .batteryLow, .batteryFull:
                    .compact(wing: IslandMetrics.wingNowPlaying)
                default:
                    .compact(wing: IslandMetrics.wingMax)
                }
            default:
                if let primary = state.layout.primary {
                    .compact(
                        wing: primary.kind == .nowPlaying ? IslandMetrics.wingNowPlaying : IslandMetrics.wingTimer)
                } else {
                    .idle
                }
            }
        let island = IslandMetrics.islandRect(size: IslandMetrics.size(for: request, notch: notch), notch: notch)
        let bubbles = state.layout.detached.enumerated().map { index, activity in
            (activity.id, IslandMetrics.bubbleRect(index: index, primary: island, notch: notch))
        }
        return (island, bubbles)
    }

    var homeInputs: HomeInputs {
        HomeInputs(
            pendingPermission: nowPlaying.pendingConsent, hasNowPlaying: nowPlaying.snapshot != nil,
            hasImminentMeeting: calendar.activities.isEmpty == false,
            hasRunningTimer: timer.current != nil, hasWeather: weatherForHome != nil,
            hasUpcomingEvent: calendar.nextEvent != nil,
            calendarAccessUndetermined: calendar.authorization == .notDetermined)
    }

    var weatherForHome: (snapshot: WeatherSnapshot, units: UnitChoice)? {
        guard settings.settings.enabledFeatures.contains(.weather), let snapshot = weather.snapshot else { return nil }
        let units = UnitPreferences.resolve(
            locale: .current, systemTemperatureSetting: UserDefaults.standard.string(forKey: "AppleTemperatureUnit"),
            override: settings.settings.temperatureUnit)
        return (snapshot, units)
    }

    var nowPlayingActions: NowPlayingActions {
        NowPlayingActions(
            playPause: { [unowned self] in Task { await nowPlaying.perform(.playPause) } },
            next: { [unowned self] in Task { await nowPlaying.perform(.next) } },
            previous: { [unowned self] in Task { await nowPlaying.perform(.previous) } },
            seek: { [unowned self] seconds in Task { await nowPlaying.perform(.seek(seconds)) } },
            toggleShuffle: { [unowned self] in Task { await nowPlaying.perform(.toggleShuffle) } },
            cycleRepeat: { [unowned self] in Task { await nowPlaying.perform(.cycleRepeat) } },
            toggleFavorite: { [unowned self] in Task { await nowPlaying.perform(.toggleFavorite) } },
            setVolume: { [unowned self] level in Task { await nowPlaying.perform(.setVolume(level)) } },
            artwork: { [unowned self] key in artwork(for: key) },
            haptic: { [unowned self] in feedback.play($0) },
            requestConsent: { [unowned self] source in Task { await nowPlaying.requestConsent(for: source) } })
    }

    private func artwork(for key: String) -> NSImage? {
        if let artworkImage, artworkImage.key == key { return artworkImage.image }
        guard let current = nowPlaying.artwork, current.key == key, let image = NSImage(data: current.data) else {
            return nil
        }
        artworkImage = (key, image)
        return image
    }

    var timerActions: TimerActions {
        TimerActions(
            start: { [unowned self] in timer.start(minutes: $0, label: nil) },
            startPomodoro: { [unowned self] in timer.startPomodoro() },
            startStopwatch: { [unowned self] in timer.startStopwatch() },
            pause: { [unowned self] in timer.pause() }, resume: { [unowned self] in timer.resume() },
            cancel: { [unowned self] in timer.cancel() }, skip: { [unowned self] in timer.skip() })
    }

    func activeIsland() -> ScreenIsland? {
        let mouse = NSEvent.mouseLocation
        return islands.values.first { $0.screen.frame.contains(mouse) }
            ?? islands.values.first { $0.screen.isMain } ?? islands.values.first
    }

    func broadcast(_ event: IslandEvent) {
        for island in islands.values { island.store.send(event) }
    }

    func updateDroplet(for island: ScreenIsland, localPoint: CGPoint?, velocity: CGSize) {
        guard settings.settings.waterDropletEffect else {
            if island.dropletTension != .zero { island.dropletTension = .zero }
            return
        }
        let target: DropletTension
        if let localPoint,
            let hoverRect = IslandRootView.hoverRegion(
                state: island.store.state, notch: island.notch,
                expandedWidth: CGFloat(settings.settings.expandedWidth)
            ).first
        {
            let exactRect = CGRect(
                x: hoverRect.minX, y: hoverRect.minY + 4, width: hoverRect.width, height: hoverRect.height - 4)
            target = DropletPhysics.compute(
                pointer: localPoint,
                islandRect: exactRect,
                velocity: velocity,
                sensitivity: settings.settings.dropletSensitivity
            )
        } else {
            target = .zero
        }
        guard target != island.dropletTension else { return }
        withAnimation(.spring(duration: 0.42, bounce: 0.12)) {
            island.dropletTension = target
        }
    }
}

/// Per-screen island parts. The store needs a panel before the window controller exists, hence the proxy.
@MainActor @Observable final class ScreenIsland {
    @ObservationIgnored var screen: ScreenDescriptor
    @ObservationIgnored var notch: NotchMetrics
    @ObservationIgnored let store: IslandStore
    @ObservationIgnored let panel: PanelProxy
    @ObservationIgnored let feedback: ScreenFeedback
    @ObservationIgnored var router: PointerRouter!
    @ObservationIgnored var hotZoneRect: CGRect?
    var dropletTension: DropletTension = .zero

    init(screen: ScreenDescriptor, store: IslandStore, panel: PanelProxy, feedback: ScreenFeedback) {
        self.screen = screen
        notch = NotchGeometry.metrics(for: screen)
        self.store = store
        self.panel = panel
        self.feedback = feedback
    }
}

@MainActor final class ScreenFeedback: FeedbackPlaying {
    private let base: FeedbackPlaying
    private let playsSounds: @MainActor () -> Bool

    init(base: FeedbackPlaying, playsSounds: @escaping @MainActor () -> Bool) {
        self.base = base
        self.playsSounds = playsSounds
    }

    func play(_ haptic: HapticKind) { base.play(haptic) }
    func play(_ sound: SoundKind) { if playsSounds() { base.play(sound) } }
}

@MainActor final class PanelProxy: PanelControlling {
    weak var target: IslandWindowController?
    var speed: @MainActor () -> Double = { 0 }
    func setMouseEventsIgnored(_ ignored: Bool) { target?.setMouseEventsIgnored(ignored) }
    func makeKey(_ key: Bool) { target?.makeKey(key) }
}
