import AppKit
import IslandCore
import IslandFeatures
import IslandServices
import OSLog
import SwiftUI
import UniformTypeIdentifiers

extension CompositionRoot {
    var quickToolsActions: QuickToolsActions {
        makeQuickToolsActions(for: nil)
    }

    func makeQuickToolsActions(for island: ScreenIsland?) -> QuickToolsActions {
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
            toggleNotePin: { [unowned self] id in quickNotes.togglePin(id) },
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
                    },
                    downloadRateText: SystemStatsService.formatRate(s.downloadBytesPerSec),
                    uploadRateText: SystemStatsService.formatRate(s.uploadBytesPerSec))
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
            pickAndPinApp: { [unowned self] in pickAppToPin() },
            removePinnedApp: { [unowned self] path in appLauncher.removeApp(path: path) },
            pinnedShortcuts: { [unowned self] in appLauncher.shortcuts },
            addShortcut: { [unowned self] name in appLauncher.addShortcut(name: name) },
            removeShortcut: { [unowned self] id in appLauncher.removeShortcut(id) },
            reminders: { [unowned self] in remindersStore.items },
            addReminder: { [unowned self] title in remindersStore.add(title) },
            toggleReminder: { [unowned self] id in remindersStore.toggle(id) },
            removeReminder: { [unowned self] id in remindersStore.remove(id) },
            appleRemindersState: { [unowned self] in
                switch appleReminders.authorization {
                case .fullAccess: .connected
                case .notDetermined: .notConnected
                case .denied, .restricted, .writeOnly: .denied
                }
            },
            appleReminders: { [unowned self] in
                appleReminders.items.map {
                    AppleReminderItem(
                        id: $0.id, title: $0.title, isCompleted: $0.isCompleted, dueDate: $0.dueDate,
                        listTitle: $0.listTitle)
                }
            },
            connectAppleReminders: { [unowned self] in Task { await appleReminders.requestAccess() } },
            addAppleReminder: { [unowned self] title in appleReminders.add(title) },
            toggleAppleReminder: { [unowned self] id in appleReminders.toggle(id) },
            removeAppleReminder: { [unowned self] id in appleReminders.remove(id) },
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
            expandedWidth: { [unowned self] in settings.settings.expandedWidth },
            toggleDetachedPopover: { [unowned self] in
                let view = AnyView(
                    DetachedMenuBarHubView()
                        .environment(\.quickTools, quickToolsActions))
                statusItem.togglePopover(rootView: view)
            },
            startKeyboardCleaningLock: { [unowned self] in
                keyboardLock.lock()
            },
            activeLyricLine: { [unowned self] snapshot in
                SyncedLyricsParser.activeLine(in: lyrics.lines, at: snapshot.position(at: time.now))
            },
            activeLyricLines: { [unowned self] snapshot in
                SyncedLyricsParser.activeAndNextLines(in: lyrics.lines, at: snapshot.position(at: time.now))
            },
            enabledQuickTools: { [unowned self] in
                settings.settings.orderedEnabledQuickTools
            },
            visualStyle: { [unowned self] in settings.settings.visualStyle },
            surfaceMaterial: { [unowned self] in settings.settings.surfaceMaterial },
            waterDropletEffect: { [unowned self] in settings.settings.waterDropletEffect },
            dropletTension: { [weak island] in island?.dropletTension ?? .zero },
            compactWingLyrics: { [unowned self] in settings.settings.compactWingLyrics },
            audioSpectrumBands: { [unowned self] in audioSpectrum.bands },
            liveAudioSpectrumEnabled: { [unowned self] in settings.settings.liveAudioSpectrumEnabled },
            quickAIMessages: { [unowned self] in quickAI.messages },
            isQuickAIGenerating: { [unowned self] in quickAI.isGenerating },
            quickAIError: { [unowned self] in quickAI.lastError },
            askQuickAI: { [unowned self] prompt in
                let config = settings.settings.quickAIConfig
                Task { await quickAI.ask(prompt, config: config) }
            },
            clearQuickAI: { [unowned self] in quickAI.clearConversation() },
            isMirrorAuthorized: { [unowned self] in
                cameraMirror.refreshAuthState()
                return cameraMirror.authState == .authorized
            },
            isMirrorDenied: { [unowned self] in cameraMirror.authState == .denied },
            startMirrorPreview: { [unowned self] in await cameraMirror.startAndMakePreviewView() },
            stopMirrorPreview: { [unowned self] in cameraMirror.stop() },
            isScreenRecording: { [unowned self] in screenRecorder.isRecording },
            startScreenRecording: { [unowned self] asGIF in
                startScreenCapture(asGIF: asGIF, selectRegion: false)
            },
            stopScreenRecording: { [unowned self] in stopScreenCapture() },
            dropletSensitivity: { [unowned self] in settings.settings.dropletSensitivity },
            recordingStartedAt: { [unowned self] in screenRecorder.startedAt },
            startScreenRecordingCrop: { [unowned self] asGIF, selectRegion in
                startScreenCapture(asGIF: asGIF, selectRegion: selectRegion)
            },
            latestClipboardText: { [unowned self] in
                NSPasteboard.general.string(forType: .string) ?? clipboardStore.entries.first?.text
            })
    }

    func syncAudioSpectrum() {
        let wantsSpectrum =
            settings.settings.enabledFeatures.contains(.nowPlaying)
            && (settings.settings.liveAudioSpectrumEnabled || settings.settings.visualStyle == .boring)
        let isPlaying = nowPlaying.snapshot?.isPlaying == true
        let anyVisible = islands.values.contains {
            switch $0.store.state.phase {
            case .compact, .peek, .expanded: true
            case .hidden, .idle, .transient: false
            }
        }
        if wantsSpectrum && isPlaying && anyVisible {
            if audioSpectrum.isActive {
                audioSpectrum.updatePlayback(isPlaying: true)
            } else {
                audioSpectrum.start(liveTapAllowed: settings.settings.liveAudioSpectrumEnabled, isPlaying: true)
            }
        } else if audioSpectrum.isActive {
            audioSpectrum.stop()
        }
    }

    func startScreenCapture(asGIF: Bool, selectRegion: Bool) {
        Task { @MainActor in
            var cropRect: CGRect?
            if selectRegion {
                broadcast(.escapePressed)
                regionSelector.instructionText = String(localized: "record.region.instruction")
                guard let selected = await regionSelector.selectRegion() else { return }
                cropRect = selected
            }

            let started = await screenRecorder.startRecording(format: asGIF ? .gif : .mp4, cropRect: cropRect)
            guard started else { return }
            feedback.play(.alignment)
            if case .success(let req) = CustomActivityRequest.make(
                id: "screen-recording",
                title: String(localized: "alert.recording.title"),
                subtitle: asGIF ? "GIF" : "MP4",
                symbol: "record.circle.fill",
                accentHex: "FF453A",
                progress: nil,
                duration: nil)
            {
                custom.show(req)
            }
        }
    }

    func stopScreenCapture() {
        Task { @MainActor in
            custom.end(id: "screen-recording")
            guard let url = await screenRecorder.stopRecording() else { return }
            do {
                try shelf.add([url])
                feedback.play(.levelChange)
                broadcast(
                    .alertRaised(
                        TransientAlert(
                            id: UUID(), kind: .custom,
                            detail: .text(
                                title: url.lastPathComponent,
                                subtitle: String(localized: "alert.recording.savedToShelf"),
                                symbol: "checkmark.circle.fill"),
                            tint: .green, duration: 2.6, priority: .normal)))
                activeIsland()?.store.send(.pageSelected(.shelf))
            } catch {
                logger.error("recording shelf save failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func observePrivacyCallActivity() {
        withObservationTracking {
            _ = deviceUsage.privacy
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let running = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
                if let appName = CallActivityDetector.activeCallApp(
                    privacy: deviceUsage.privacy, runningBundleIDs: running)
                {
                    if case .success(let req) = CustomActivityRequest.make(
                        id: "active-call",
                        title: appName,
                        subtitle: String(localized: "alert.callActive"),
                        symbol: "phone.wave.2.fill",
                        accentHex: "32D74B",
                        progress: nil,
                        duration: nil)
                    {
                        custom.show(req)
                    }
                } else {
                    custom.end(id: "active-call")
                }
                observePrivacyCallActivity()
            }
        }
    }

    private func pickAppToPin() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let name = FileManager.default.displayName(atPath: url.path()).replacingOccurrences(of: ".app", with: "")
        appLauncher.addApp(name: name, path: url.path())
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
}
