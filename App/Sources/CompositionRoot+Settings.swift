import AppKit
import CoreGraphics
import CoreLocation
import IslandCore
import IslandServices

extension CompositionRoot {
    var isMuted: Bool { (settings.settings.muteUntil ?? .distantPast) > time.now }

    func observeSettings() {
        withObservationTracking {
            _ = settings.settings
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.applySettings()
                self?.observeSettings()
            }
        }
    }

    func applySettings() {
        let current = settings.settings
        defer { appliedSettings = current }
        if appliedSettings?.displayMode != current.displayMode { syncWindows() }
        if appliedSettings?.islandOptions != current.islandOptions {
            broadcast(.optionsChanged(current.islandOptions))
        }
        if appliedSettings?.hideNotchBar != current.hideNotchBar {
            for (id, island) in islands {
                windows.controller(for: id)?.setNotchBackdropVisible(
                    current.hideNotchBar && island.store.state.phase != .hidden)
            }
        }
        statusItem.isVisible = current.showMenuBarIcon
        if let previous = appliedSettings { applyFeatureChanges(from: previous, to: current) }
    }

    private func applyFeatureChanges(from old: IslandSettings, to new: IslandSettings) {
        func turned(_ f: IslandFeature) -> Bool? {
            let (was, now) = (old.enabledFeatures.contains(f), new.enabledFeatures.contains(f))
            return was == now ? nil : now
        }
        if let on = turned(.nowPlaying) { on ? nowPlaying.start() : nowPlaying.stop() }
        if let on = turned(.calendar) { on ? calendar.start() : calendar.stop() }
        if let on = turned(.battery) { on ? power.start() : power.stop() }
        let btWas = old.enabledFeatures.contains(.battery) && old.bluetoothAlertsEnabled
        let btNow = new.enabledFeatures.contains(.battery) && new.bluetoothAlertsEnabled
        if btWas != btNow { btNow ? audioDevices.start() : audioDevices.stop() }
        if let on = turned(.privacyIndicator) { on ? deviceUsage.start() : deviceUsage.stop() }
        if let on = turned(.shelf) { on ? fileDrags.start() : fileDrags.stop() }
        if let on = turned(.customActivities) {
            on ? competing.start() : competing.stop()
            on ? externalDrives.start() : externalDrives.stop()
        }
        let capsWas = old.enabledFeatures.contains(.customActivities) || old.doubleTapOptionToToggle
        let capsNow = new.enabledFeatures.contains(.customActivities) || new.doubleTapOptionToToggle
        if capsWas != capsNow { capsNow ? capsLock.start() : capsLock.stop() }
        if old.weatherLocation != new.weatherLocation, new.enabledFeatures.contains(.weather) {
            Task { await weather.islandBecameVisible(force: true) }
        }
        if old.shelfRetentionDays != new.shelfRetentionDays, new.enabledFeatures.contains(.shelf) {
            shelf.cleanUp()
        }
        let downloadsWas = old.enabledFeatures.contains(.downloads) && old.downloadsAlertsOptedIn
        let downloadsNow = new.enabledFeatures.contains(.downloads) && new.downloadsAlertsOptedIn
        if downloadsWas != downloadsNow { downloadsNow ? downloads.start() : downloads.stop() }
        if old.liveAudioSpectrumEnabled != new.liveAudioSpectrumEnabled || old.visualStyle != new.visualStyle {
            audioSpectrum.stop()
            syncAudioSpectrum()
        }
        if !new.waterDropletEffect {
            for island in islands.values where island.dropletTension != .zero {
                island.dropletTension = .zero
            }
        }
        if !new.floatingShelfBasket || !new.enabledFeatures.contains(.shelf) {
            shelfBasket.update(isDragging: false, mouse: .zero, screens: screens, enabled: false)
        }
        hub.refresh()
    }

    func permissionState(_ feature: IslandFeature) -> PermissionState? {
        _ = permissionSignal.revision
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

    func requestPermission(_ feature: IslandFeature) {
        switch feature {
        case .nowPlaying:
            Task {
                await nowPlaying.requestConsent(for: .music)
                permissionSignal.revision &+= 1
            }
        case .calendar:
            Task {
                await calendar.requestAccess()
                permissionSignal.revision &+= 1
            }
        case .weather:
            Task {
                await weather.islandBecameVisible()
                permissionSignal.revision &+= 1
            }
        default: break
        }
    }

    func extraPermissionState(_ kind: ExtraPermissionKind) -> PermissionState {
        _ = permissionSignal.revision
        switch kind {
        case .reminders:
            switch appleReminders.authorization {
            case .fullAccess: return .granted
            case .notDetermined: return .notRequested
            case .denied, .restricted, .writeOnly: return .denied
            }
        case .camera:
            cameraMirror.refreshAuthState()
            switch cameraMirror.authState {
            case .authorized: return .granted
            case .notDetermined: return .notRequested
            case .denied: return .denied
            case .unavailable: return .unavailable
            }
        case .audioTap:
            return settings.settings.liveAudioSpectrumEnabled ? .systemManaged : .notRequested
        case .screenCapture:
            return ScreenRecorderService.hasScreenCaptureAccess ? .granted : .notRequested
        case .spotify:
            #if LUNULA_SPOTIFY
                switch nowPlaying.permissions[.spotify] {
                case .granted?: return .granted
                case .denied?: return .denied
                case .needsConsent?: return .notRequested
                case .notRunning?, nil: return .unavailable
                }
            #else
                return .unavailable
            #endif
        }
    }

    func requestExtraPermission(_ kind: ExtraPermissionKind) {
        switch kind {
        case .reminders:
            Task {
                await appleReminders.requestAccess()
                permissionSignal.revision &+= 1
            }
        case .camera:
            Task {
                _ = await cameraMirror.requestPermissionOnly()
                permissionSignal.revision &+= 1
            }
        case .audioTap:
            settings.update { $0.liveAudioSpectrumEnabled = true }
            permissionSignal.revision &+= 1
        case .screenCapture:
            _ = CGRequestScreenCaptureAccess()
            permissionSignal.revision &+= 1
        case .spotify:
            #if LUNULA_SPOTIFY
                Task {
                    await nowPlaying.requestConsent(for: .spotify)
                    permissionSignal.revision &+= 1
                }
            #endif
        }
    }

    func localizedAIStatus(_ kind: QuickAIStatusKind?) -> String? {
        guard let kind else { return nil }
        switch kind {
        case .ollamaConnected(let count):
            return String(localized: "ai.status.ollamaConnected \(Int64(count))")
        case .providerConnected(let provider):
            return String(localized: "ai.status.providerConnected \(provider.displayName)")
        case .missingAPIKey(let provider):
            return String(localized: "ai.error.missingKey \(provider.displayName)")
        case .invalidResponse:
            return String(localized: "ai.error.invalidResponse")
        case .emptyResponse(let provider):
            return String(localized: "ai.error.emptyResponse \(provider.displayName)")
        case .httpError(let statusCode, let provider):
            return String(localized: "ai.error.httpError \(Int64(statusCode)) \(provider.displayName)")
        case .serverMessage(let message):
            return message
        }
    }

    func contextMenu() -> NSMenu {
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
                settings: settings,
                launchAtLogin: launchAtLogin,
                permission: { [unowned self] in permissionState($0) },
                request: { [unowned self] in requestPermission($0) },
                searchWeatherCity: { [unowned self] query in
                    let lang = Locale.current.language.languageCode?.identifier ?? "en"
                    return await weather.search(query, language: lang)
                },
                hasAIKey: { [unowned self] provider in quickAI.hasAPIKey(for: provider) },
                saveAIKey: { [unowned self] key, provider in quickAI.saveAPIKey(key, for: provider) },
                clearAIKey: { [unowned self] provider in quickAI.clearAPIKey(for: provider) },
                extraPermission: { [unowned self] kind in extraPermissionState(kind) },
                requestExtraPermission: { [unowned self] kind in requestExtraPermission(kind) },
                ollamaModels: { [unowned self] in quickAI.availableOllamaModels },
                refreshOllamaModels: { [unowned self] endpoint in
                    await quickAI.fetchOllamaModels(endpoint: endpoint)
                },
                testAIConnection: { [unowned self] config in
                    let ok = await quickAI.testConnection(config: config)
                    return (
                        ok, localizedAIStatus(quickAI.connectionStatusKind) ?? quickAI.connectionStatusMessage ?? ""
                    )
                },
                resetDefaults: { [unowned self] in
                    settings.update {
                        var defaults = IslandSettings.default
                        defaults.hasCompletedOnboarding = true
                        $0 = defaults
                    }
                }
            )
        }
        settingsWindow?.show()
    }
}
