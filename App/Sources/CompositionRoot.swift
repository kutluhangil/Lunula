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

    private let logger = Logger(subsystem: "com.kutluhangul.lunula", category: "app")
    private let time = SystemTime()
    private let settings = SettingsStore(defaults: .standard)
    private let launchAtLogin = LaunchAtLoginService()
    private let windows = IslandWindowManager()
    private lazy var hub = ActivityHub(time: time, settings: settings)
    private lazy var timer = TimerController(time: time, defaults: .standard)
    private lazy var nowPlaying: NowPlayingCoordinator = {
        let runner = ScriptRunner()
        var sources: [NowPlayingSource] = [MusicSource(runner: runner)]
        #if LUNULA_SPOTIFY
            let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            sources.append(SpotifySource(runner: runner, cacheDirectory: caches.appendingPathComponent("Artwork")))
        #endif
        return NowPlayingCoordinator(
            sources: sources, time: time, accents: ArtworkAccentStore(), permissions: AutomationPermissionChecker())
    }()
    private var artworkImage: (key: String, image: NSImage)?
    private lazy var calendar = CalendarService(reader: EventKitReader(), time: time)
    private lazy var shelf = ShelfStore(
        directory: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Shelf"),
        bookmarks: SecurityScopedBookmarkCoding(), time: time, settings: settings)
    private lazy var fileDrags = FileDragMonitor(
        screens: { [unowned self] in islands.values.map(\.screen) },
        send: { [unowned self] id, event in islands[id]?.store.send(event) })
    private var shelfIcons: [UUID: NSImage] = [:]
    private let power = PowerMonitor()
    private lazy var keepAwake = KeepAwakeService(time: time)
    private lazy var audioDevices = AudioDeviceService()
    private lazy var quickNotes = QuickNotesStore(defaults: .standard, time: time)
    private lazy var clipboardStore = ClipboardHistoryStore(defaults: .standard, time: time)
    private lazy var pasteboardMonitor = PasteboardMonitor(store: clipboardStore)
    private lazy var teleprompter = TeleprompterStore(defaults: .standard)
    private lazy var appLauncher = AppLauncherStore(defaults: .standard)
    private lazy var remindersStore = QuickRemindersStore(defaults: .standard, time: time)
    private lazy var stocksStore = StocksWatchlistStore(defaults: .standard)
    private lazy var stocksService = StocksService(store: stocksStore)
    private lazy var aiUsageStore = AIUsageStore(defaults: .standard, time: time)
    private lazy var focusHistory = FocusHistoryStore(defaults: .standard)
    private lazy var systemStats = SystemStatsService()
    private lazy var externalDrives = ExternalDriveMonitor()
    private lazy var capsLock = CapsLockMonitor()
    private lazy var lyrics = LyricsService()
    private lazy var downloads = DownloadsWatcher()
    private lazy var deviceUsage = DeviceUsageMonitor(reader: SystemDeviceUsageReader())
    lazy var custom = CustomActivityController(time: time)
    private lazy var router = URLRouter(
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
        toggle: { [unowned self] in activeIsland()?.store.send(.toggleRequested) },
        time: time)
    private lazy var weather = WeatherService(
        provider: OpenMeteoProvider(),
        cache: WeatherCache(
            fileURL: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("weather.json")),
        location: LocationService(), settings: settings, time: time)
    private lazy var feedback = SystemFeedbackPlayer(preferences: { [unowned self] in
        let muted = isMuted
        return (settings.settings.hapticsEnabled && !muted, settings.settings.soundsEnabled && !muted)
    })
    private lazy var statusItem = StatusItemController(menu: { [unowned self] in contextMenu() })
    private var screenService: ScreenService?
    private var islands: [UInt32: ScreenIsland] = [:]
    private var screens: [ScreenDescriptor] = []
    private var settingsWindow: SettingsWindowController?
    private var onboarding: OnboardingWindowController?
    private lazy var competing = CompetingAppNotice(settings: settings)
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
        hub.onLayoutChange = { [unowned self] layout in
            lyrics.update(for: nowPlaying.snapshot)
            broadcast(.activitiesChanged(layout))
        }
        hub.onAlert = { [unowned self] alert in
            if alert.kind == .timerFinished {
                focusHistory.recordCompletedMinutes(25, on: time.now)
            }
            broadcast(.alertRaised(alert))
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
        if settings.settings.enabledFeatures.contains(.battery) { power.start() }
        hub.register(calendar, feature: .calendar)
        if settings.settings.enabledFeatures.contains(.calendar) { calendar.start() }
        hub.register(alerts: competing, feature: .customActivities)
        competing.start()
        hub.register(alerts: externalDrives, feature: .customActivities)
        externalDrives.start()
        capsLock.labelProvider = { isOn in
            String(localized: isOn ? "alert.capsLockOn" : "alert.capsLockOff")
        }
        hub.register(alerts: capsLock, feature: .customActivities)
        capsLock.start()
        pasteboardMonitor.start()
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

    private lazy var fullscreen = FullscreenMonitor(
        screens: { [unowned self] in screens },
        frontmostPID: { NSWorkspace.shared.frontmostApplication?.processIdentifier })

    func handle(_ url: URL) {
        Signposts.island.emitEvent("url")
        router.handle(url)
    }

    // MARK: - Windows

    private func syncWindows() {
        let signpost = Signposts.island.beginInterval("syncWindows")
        defer { Signposts.island.endInterval("syncWindows", signpost) }
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
            controller.container.hoverRegion = { [unowned island] in
                IslandRootView.hoverRegion(state: island.store.state, notch: island.notch)
            }
            controller.container.onHoverChange = { [weak router = island.router] in router?.islandHoverChanged($0) }
            controller.onResignKey = { [weak island] in island?.store.send(.clickedOutside) }
            island.hotZoneRect = nil
            layoutHotZone(id)
        }
        fullscreen.refresh()
    }

    private func makeIsland(for screen: ScreenDescriptor) -> AnyView {
        let panel = PanelProxy()
        // Alerts reach every screen's store; only the main display's island plays sounds, so one alert = one sound.
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
            .environment(\.quickTools, quickToolsActions)
            .environment(
                \.calendarActions,
                CalendarActions(
                    join: { NSWorkspace.shared.open($0) },
                    requestAccess: { [unowned self] in Task { await calendar.requestAccess() } },
                    nextEvent: { [unowned self] in calendar.nextEvent })
            )
            .environment(
                \.alertActions,
                AlertActions(
                    revealInFinder: { NSWorkspace.shared.activateFileViewerSelecting([$0]) },
                    addToShelf: { [unowned self] url in shelfActions.add([url]) })))
    }

    /// While closed the hot zone hugs the visible island, which widens when an activity shows in the wings.
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
                let anyOpen = islands.values.contains { $0.store.state.phase.isOpen }
                nowPlaying.setExpanded(anyOpen)
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

    /// Feature phases bind their inputs here as they land.
    private var homeInputs: HomeInputs {
        HomeInputs(
            pendingPermission: nowPlaying.pendingConsent, hasNowPlaying: nowPlaying.snapshot != nil,
            hasImminentMeeting: calendar.activities.isEmpty == false,
            hasRunningTimer: timer.current != nil, hasWeather: weatherForHome != nil,
            hasUpcomingEvent: calendar.nextEvent != nil,
            calendarAccessUndetermined: calendar.authorization == .notDetermined)
    }

    private var weatherForHome: (snapshot: WeatherSnapshot, units: UnitChoice)? {
        guard settings.settings.enabledFeatures.contains(.weather), let snapshot = weather.snapshot else { return nil }
        let units = UnitPreferences.resolve(
            locale: .current, systemTemperatureSetting: UserDefaults.standard.string(forKey: "AppleTemperatureUnit"),
            override: settings.settings.temperatureUnit)
        return (snapshot, units)
    }

    private var shelfActions: ShelfActions {
        ShelfActions(
            items: { [unowned self] in shelfModels },
            add: { [unowned self] urls in
                guard !urls.isEmpty else { return }
                do {
                    try shelf.add(urls)
                    feedback.play(.levelChange)
                } catch {
                    logger.error("shelf add failed: \(error.localizedDescription, privacy: .public)")
                }
            },
            remove: { [unowned self] id in
                shelf.remove(id)
                shelfIcons[id] = nil
            },
            reveal: { [unowned self] id in
                guard let item = shelf.items.first(where: { $0.id == id }) else { return }
                _ = shelf.withAccess(to: item) { NSWorkspace.shared.activateFileViewerSelecting([$0]) }
            },
            airDrop: { [unowned self] ids in shareFiles(ids, via: NSSharingService(named: .sendViaAirDrop)) },
            share: { [unowned self] ids in shareFiles(ids, via: nil) },
            dragItem: { [unowned self] id in
                guard let item = shelf.items.first(where: { $0.id == id }),
                    case .available(let url) = shelf.status(of: item)
                else { return nil }
                return NSItemProvider(contentsOf: url)
            },
            convertImage: { [unowned self] id, rawFormat in
                convertShelfImage(id: id, rawFormat: rawFormat)
            },
            compressToZip: { [unowned self] ids in
                compressShelfItems(ids: ids)
            },
            expandArchive: { [unowned self] id in
                expandShelfArchive(id: id)
            },
            copyTextOCR: { [unowned self] id in
                copyShelfItemOCR(id: id)
            },
            stageClipboardImage: { [unowned self] in
                stageClipboardImageToShelf()
            })
    }

    private func expandShelfArchive(id: UUID) {
        guard let item = shelf.items.first(where: { $0.id == id }),
            case .available(let url) = shelf.status(of: item)
        else { return }
        let outDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ShelfExpanded")
        let scoped = url.startAccessingSecurityScopedResource()
        Task.detached { [weak self] in
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard let expanded = try? ShelfConverter.extractArchive(at: url, in: outDir) else { return }
            await MainActor.run {
                try? self?.shelf.add([expanded])
                self?.feedback.play(.levelChange)
            }
        }
    }

    private func stageClipboardImageToShelf() {
        let outDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ShelfScreenshots")
        guard let staged = try? ShelfConverter.stageClipboardImage(from: .general, in: outDir) else { return }
        try? shelf.add([staged])
        feedback.play(.levelChange)
    }

    private func convertShelfImage(id: UUID, rawFormat: String) {
        guard let format = ShelfImageFormat(rawValue: rawFormat),
            let item = shelf.items.first(where: { $0.id == id }),
            case .available(let url) = shelf.status(of: item)
        else { return }
        let outDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ShelfConverted")
        let scoped = url.startAccessingSecurityScopedResource()
        Task.detached { [weak self] in
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard let converted = try? ShelfConverter.convertImage(at: url, to: format, in: outDir) else { return }
            await MainActor.run {
                try? self?.shelf.add([converted])
                self?.feedback.play(.levelChange)
            }
        }
    }

    private func compressShelfItems(ids: [UUID]) {
        let urls = ids.compactMap { id -> URL? in
            guard let item = shelf.items.first(where: { $0.id == id }),
                case .available(let url) = shelf.status(of: item)
            else { return nil }
            return url
        }
        guard !urls.isEmpty else { return }
        let outDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ShelfArchives")
        let scoped = urls.filter { $0.startAccessingSecurityScopedResource() }
        Task.detached { [weak self] in
            defer { for url in scoped { url.stopAccessingSecurityScopedResource() } }
            guard let archive = try? ShelfConverter.createArchive(from: urls, in: outDir) else { return }
            await MainActor.run {
                try? self?.shelf.add([archive])
                self?.feedback.play(.levelChange)
            }
        }
    }

    private func copyShelfItemOCR(id: UUID) {
        guard let item = shelf.items.first(where: { $0.id == id }),
            case .available(let url) = shelf.status(of: item)
        else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        Task.detached { [weak self] in
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard let text = try? ShelfConverter.extractText(from: url) else { return }
            await MainActor.run {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
                self?.feedback.play(.alignment)
                self?.broadcast(
                    .alertRaised(
                        TransientAlert(
                            id: UUID(), kind: .custom,
                            detail: .text(
                                title: String(localized: "alert.ocrCopied"),
                                subtitle: String(text.prefix(42)),
                                symbol: "text.viewfinder"),
                            tint: .neutral, duration: 2.2, priority: .normal)))
            }
        }
    }

    private var quickToolsActions: QuickToolsActions {
        QuickToolsActions(
            isKeepAwakeActive: { [unowned self] in keepAwake.isActive },
            toggleKeepAwake: { [unowned self] in
                keepAwake.toggle()
                feedback.play(.alignment)
            },
            activateKeepAwake: { [unowned self] duration in
                keepAwake.activate(duration: duration)
                feedback.play(.alignment)
            },
            isMicMuted: { [unowned self] in audioDevices.isInputMuted },
            toggleMicMute: { [unowned self] in
                let muted = audioDevices.toggleInputMute()
                feedback.play(.alignment)
                broadcast(
                    .alertRaised(
                        TransientAlert(
                            id: UUID(), kind: .custom,
                            detail: .text(
                                title: String(localized: muted ? "alert.micMuted" : "alert.micUnmuted"),
                                subtitle: nil,
                                symbol: muted ? "mic.slash.fill" : "mic.fill"),
                            tint: muted ? .red : .green, duration: 1.8, priority: .normal)))
            },
            outputDevices: { [unowned self] in
                audioDevices.outputDevices.map {
                    AudioOutputDeviceItem(id: $0.id, name: $0.name, isCurrent: $0.isCurrent)
                }
            },
            selectOutputDevice: { [unowned self] id in
                audioDevices.selectOutputDevice(id)
                feedback.play(.alignment)
            },
            pickColor: { [unowned self] in
                sampleScreenColor()
            },
            notes: { [unowned self] in quickNotes.notes },
            addNote: { [unowned self] text in quickNotes.add(text) },
            removeNote: { [unowned self] id in quickNotes.remove(id) },
            clipboardEntries: { [unowned self] in
                pasteboardMonitor.checkNow()
                return clipboardStore.entries
            },
            toggleClipboardPin: { [unowned self] id in clipboardStore.togglePin(id) },
            removeClipboardEntry: { [unowned self] id in clipboardStore.remove(id) },
            clearUnpinnedClipboard: { [unowned self] in clipboardStore.clearUnpinned() },
            snippets: { [unowned self] in clipboardStore.snippets },
            addSnippet: { [unowned self] title, body in clipboardStore.addSnippet(title: title, body: body) },
            removeSnippet: { [unowned self] id in clipboardStore.removeSnippet(id) },
            teleprompterScript: { [unowned self] in teleprompter.script },
            setTeleprompterScript: { [unowned self] script in teleprompter.script = script },
            teleprompterSpeed: { [unowned self] in teleprompter.pointsPerSecond },
            setTeleprompterSpeed: { [unowned self] speed in teleprompter.pointsPerSecond = speed },
            systemStats: { [unowned self] in
                let s = systemStats.refresh()
                externalDrives.refreshDrives()
                return SystemStatsItem(
                    cpuPercent: s.cpuPercent,
                    memoryPercent: s.memoryPercent,
                    memoryUsedGB: s.memoryUsedGB,
                    memoryTotalGB: s.memoryTotalGB,
                    wirelessBatteries: s.wirelessBatteries.map {
                        WirelessBatteryItem(id: $0.id, name: $0.name, level: $0.level)
                    },
                    mountedDrives: externalDrives.drives.map {
                        MountedDriveItem(name: $0.name, url: $0.url)
                    })
            },
            ejectDrive: { [unowned self] url in
                externalDrives.eject(url, safeDisconnectMessage: String(localized: "alert.safeToDisconnect"))
            },
            openURL: { url in NSWorkspace.shared.open(url) },
            pinnedApps: { [unowned self] in appLauncher.apps },
            launchApp: { path in
                NSWorkspace.shared.openApplication(
                    at: URL(fileURLWithPath: path), configuration: NSWorkspace.OpenConfiguration())
            },
            pinnedShortcuts: { [unowned self] in appLauncher.shortcuts },
            addShortcut: { [unowned self] name in appLauncher.addShortcut(name: name) },
            removeShortcut: { [unowned self] id in appLauncher.removeShortcut(id) },
            reminders: { [unowned self] in remindersStore.items },
            addReminder: { [unowned self] title in remindersStore.add(title) },
            toggleReminder: { [unowned self] id in remindersStore.toggle(id) },
            removeReminder: { [unowned self] id in remindersStore.remove(id) },
            stockQuotes: { [unowned self] in stocksStore.quotes },
            refreshStocks: { [unowned self] in stocksService.refreshAll() },
            addStockSymbol: { [unowned self] sym in stocksStore.addSymbol(sym) },
            removeStockSymbol: { [unowned self] sym in stocksStore.removeSymbol(sym) },
            aiProviders: { [unowned self] in aiUsageStore.providers },
            pendingApprovals: { [unowned self] in aiUsageStore.pendingApprovals },
            resolveApproval: { [unowned self] id, approved in
                aiUsageStore.resolveApproval(id: id, approved: approved)
                feedback.play(.alignment)
                DistributedNotificationCenter.default().postNotificationName(
                    NSNotification.Name("com.kutluhangul.lunula.agentDecision"),
                    object: id,
                    userInfo: ["id": id, "approved": approved],
                    deliverImmediately: true)
            },
            focusStreakDays: { [unowned self] in focusHistory.streakDays(at: time.now) },
            focusLast7Days: { [unowned self] in focusHistory.last7Days(at: time.now) },
            timerMascot: { [unowned self] in settings.settings.timerMascot },
            pillVerticalOffset: { [unowned self] in settings.settings.pillVerticalOffset },
            hideNotchBar: { [unowned self] in settings.settings.hideNotchBar },
            useGlassCards: { [unowned self] in settings.settings.useGlassCards },
            toggleDetachedPopover: { [unowned self] in
                let view = AnyView(
                    DetachedMenuBarHubView()
                        .environment(\.quickTools, quickToolsActions))
                statusItem.togglePopover(rootView: view)
            },
            activeLyricLine: { [unowned self] snapshot in
                SyncedLyricsParser.activeLine(in: lyrics.lines, at: snapshot.position(at: time.now))
            })
    }

    private func sampleScreenColor() {
        NSColorSampler().show { [weak self] picked in
            Task { @MainActor [weak self] in
                guard let self, let srgb = picked?.usingColorSpace(.sRGB) else { return }
                let rgba = RGBAColor(
                    red: Double(srgb.redComponent), green: Double(srgb.greenComponent),
                    blue: Double(srgb.blueComponent))
                let hex = rgba.hexString
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(hex, forType: .string)
                feedback.play(.alignment)
                broadcast(
                    .alertRaised(
                        TransientAlert(
                            id: UUID(), kind: .custom,
                            detail: .text(
                                title: hex, subtitle: String(localized: "alert.colorCopied"),
                                symbol: "eyedropper.halffull"),
                            tint: .accent(rgba), duration: 2.4, priority: .normal)))
            }
        }
    }

    private var shelfModels: [ShelfItemModel] {
        shelf.items.map { item in
            let status = shelf.status(of: item)
            let icon =
                shelfIcons[item.id]
                ?? shelf.withAccess(to: item) { NSWorkspace.shared.icon(forFile: $0.path()) }
                ?? NSImage(systemSymbolName: "doc", accessibilityDescription: nil)!
            if case .available = status { shelfIcons[item.id] = icon }
            let isReference = if case .reference = item.storage { true } else { false }
            return ShelfItemModel(
                id: item.id, name: item.displayName, icon: icon, isReference: isReference, isMissing: status == .missing
            )
        }
    }

    /// AirDrop or the share sheet for the selected files, anchored to the island panel under the mouse.
    private func shareFiles(_ ids: [UUID], via service: NSSharingService?) {
        let urls = ids.compactMap { id -> URL? in
            guard let item = shelf.items.first(where: { $0.id == id }),
                case .available(let url) = shelf.status(of: item)
            else { return nil }
            return url
        }
        guard !urls.isEmpty else { return }
        let scoped = urls.filter { $0.startAccessingSecurityScopedResource() }
        defer { for url in scoped { url.stopAccessingSecurityScopedResource() } }
        if let service {
            service.perform(withItems: urls)
        } else if let view = activeIsland().flatMap({ windows.controller(for: $0.screen.id)?.container }) {
            NSSharingServicePicker(items: urls).show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        }
    }

    private var nowPlayingActions: NowPlayingActions {
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

    /// Decoded once per track; image decoding of a few hundred KB stays well under a frame.
    private func artwork(for key: String) -> NSImage? {
        if let artworkImage, artworkImage.key == key { return artworkImage.image }
        guard let current = nowPlaying.artwork, current.key == key, let image = NSImage(data: current.data) else {
            return nil
        }
        artworkImage = (key, image)
        return image
    }

    private var timerActions: TimerActions {
        TimerActions(
            start: { [unowned self] in timer.start(minutes: $0, label: nil) },
            startPomodoro: { [unowned self] in timer.startPomodoro() },
            startStopwatch: { [unowned self] in timer.startStopwatch() },
            pause: { [unowned self] in timer.pause() }, resume: { [unowned self] in timer.resume() },
            cancel: { [unowned self] in timer.cancel() }, skip: { [unowned self] in timer.skip() })
    }

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
        if let previous = appliedSettings { applyFeatureChanges(from: previous, to: current) }
    }

    /// Starts or stops services when the user toggles a feature in Settings (spec §8: stop releases everything).
    private func applyFeatureChanges(from old: IslandSettings, to new: IslandSettings) {
        func turned(_ f: IslandFeature) -> Bool? {
            let (was, now) = (old.enabledFeatures.contains(f), new.enabledFeatures.contains(f))
            return was == now ? nil : now
        }
        if let on = turned(.nowPlaying) { on ? nowPlaying.start() : nowPlaying.stop() }
        if let on = turned(.calendar) { on ? calendar.start() : calendar.stop() }
        if let on = turned(.battery) { on ? power.start() : power.stop() }
        if let on = turned(.privacyIndicator) { on ? deviceUsage.start() : deviceUsage.stop() }
        if let on = turned(.shelf) { on ? fileDrags.start() : fileDrags.stop() }
        if old.shelfRetentionDays != new.shelfRetentionDays, new.enabledFeatures.contains(.shelf) {
            shelf.cleanUp()
        }
        let downloadsWas = old.enabledFeatures.contains(.downloads) && old.downloadsAlertsOptedIn
        let downloadsNow = new.enabledFeatures.contains(.downloads) && new.downloadsAlertsOptedIn
        if downloadsWas != downloadsNow { downloadsNow ? downloads.start() : downloads.stop() }
        hub.refresh()
    }

    private func permissionState(_ feature: IslandFeature) -> PermissionState? {
        switch feature {
        case .nowPlaying:
            switch nowPlaying.permissions[.music] {
            case .granted?: return .granted
            case .denied?: return .denied
            case .needsConsent?: return .notRequested
            case .notRunning?, nil: return .unavailable
            }
        case .calendar:
            switch calendar.authorization {
            case .fullAccess: return .granted
            case .notDetermined: return .notRequested
            case .denied, .restricted, .writeOnly: return .denied
            }
        case .weather:
            switch CLLocationManager().authorizationStatus {
            case .authorizedAlways, .authorized: return .granted
            case .notDetermined: return .notRequested
            default: return .denied
            }
        default:
            return nil
        }
    }

    private func requestPermission(_ feature: IslandFeature) {
        switch feature {
        case .nowPlaying: Task { await nowPlaying.requestConsent(for: .music) }
        case .calendar: Task { await calendar.requestAccess() }
        case .weather: Task { await weather.islandBecameVisible() }
        default: break
        }
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
            var tabs = SettingsTab.baseTabs(settings: settings, launchAtLogin: launchAtLogin)
            tabs.insert(
                SettingsTab(
                    id: "activities", titleKey: "settings.tab.activities", symbol: "square.stack",
                    makeView: { [unowned self] in
                        AnyView(
                            ActivitiesSettingsView(
                                settings: settings, permission: { [unowned self] in permissionState($0) },
                                request: { [unowned self] in requestPermission($0) }))
                    }), at: 1)
            tabs.insert(
                SettingsTab(
                    id: "appearance", titleKey: "settings.tab.appearance", symbol: "paintbrush",
                    makeView: { [unowned self] in AnyView(AppearanceSettingsView(settings: settings)) }), at: 2)
            settingsWindow = SettingsWindowController(tabs: tabs)
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
    let feedback: ScreenFeedback
    var router: PointerRouter!
    var hotZoneRect: CGRect?

    init(screen: ScreenDescriptor, store: IslandStore, panel: PanelProxy, feedback: ScreenFeedback) {
        self.screen = screen
        notch = NotchGeometry.metrics(for: screen)
        self.store = store
        self.panel = panel
        self.feedback = feedback
    }
}

@MainActor private final class ScreenFeedback: FeedbackPlaying {
    private let base: FeedbackPlaying
    private let playsSounds: @MainActor () -> Bool

    init(base: FeedbackPlaying, playsSounds: @escaping @MainActor () -> Bool) {
        self.base = base
        self.playsSounds = playsSounds
    }

    func play(_ haptic: HapticKind) { base.play(haptic) }
    func play(_ sound: SoundKind) { if playsSounds() { base.play(sound) } }
}

@MainActor private final class PanelProxy: PanelControlling {
    weak var target: IslandWindowController?
    /// Pointer speed from the router, which is created after the store.
    var speed: @MainActor () -> Double = { 0 }
    func setMouseEventsIgnored(_ ignored: Bool) { target?.setMouseEventsIgnored(ignored) }
    func makeKey(_ key: Bool) { target?.makeKey(key) }
}
