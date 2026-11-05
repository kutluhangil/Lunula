import Foundation
import IslandCore
import SwiftUI

public struct AudioOutputDeviceItem: Identifiable, Equatable, Sendable {
    public var id: UInt32
    public var name: String
    public var isCurrent: Bool

    public init(id: UInt32, name: String, isCurrent: Bool) {
        self.id = id
        self.name = name
        self.isCurrent = isCurrent
    }
}

public struct WirelessBatteryItem: Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var level: Int

    public init(id: String, name: String, level: Int) {
        self.id = id
        self.name = name
        self.level = level
    }
}

public struct MountedDriveItem: Identifiable, Equatable, Sendable {
    public var id: String { url.path() }
    public var name: String
    public var url: URL

    public init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
}

public struct SystemStatsItem: Equatable, Sendable {
    public var cpuPercent: Int
    public var memoryPercent: Int
    public var memoryUsedGB: Double
    public var memoryTotalGB: Double
    public var wirelessBatteries: [WirelessBatteryItem]
    public var mountedDrives: [MountedDriveItem]

    public init(
        cpuPercent: Int = 0, memoryPercent: Int = 0, memoryUsedGB: Double = 0, memoryTotalGB: Double = 0,
        wirelessBatteries: [WirelessBatteryItem] = [], mountedDrives: [MountedDriveItem] = []
    ) {
        self.cpuPercent = cpuPercent
        self.memoryPercent = memoryPercent
        self.memoryUsedGB = memoryUsedGB
        self.memoryTotalGB = memoryTotalGB
        self.wirelessBatteries = wirelessBatteries
        self.mountedDrives = mountedDrives
    }
}

/// System utility actions and state injected by CompositionRoot into IslandFeatures without importing IslandServices.
public struct QuickToolsActions {
    public var isKeepAwakeActive: @MainActor () -> Bool = { false }
    public var toggleKeepAwake: @MainActor () -> Void = {}
    public var activateKeepAwake: @MainActor (TimeInterval?) -> Void = { _ in }
    public var isMicMuted: @MainActor () -> Bool = { false }
    public var toggleMicMute: @MainActor () -> Void = {}
    public var outputDevices: @MainActor () -> [AudioOutputDeviceItem] = { [] }
    public var selectOutputDevice: @MainActor (UInt32) -> Void = { _ in }
    public var pickColor: @MainActor () -> Void = {}
    public var captureScreenRegion: @MainActor () -> Void = {}
    public var notes: @MainActor () -> [QuickNote] = { [] }
    public var addNote: @MainActor (String) -> Void = { _ in }
    public var removeNote: @MainActor (UUID) -> Void = { _ in }
    public var clipboardEntries: @MainActor () -> [ClipboardEntry] = { [] }
    public var toggleClipboardPin: @MainActor (UUID) -> Void = { _ in }
    public var removeClipboardEntry: @MainActor (UUID) -> Void = { _ in }
    public var clearUnpinnedClipboard: @MainActor () -> Void = {}
    public var snippets: @MainActor () -> [TextSnippet] = { [] }
    public var addSnippet: @MainActor (String, String) -> Void = { _, _ in }
    public var removeSnippet: @MainActor (UUID) -> Void = { _ in }
    public var teleprompterScript: @MainActor () -> String = { "" }
    public var setTeleprompterScript: @MainActor (String) -> Void = { _ in }
    public var teleprompterSpeed: @MainActor () -> Double = { 24 }
    public var setTeleprompterSpeed: @MainActor (Double) -> Void = { _ in }
    public var systemStats: @MainActor () -> SystemStatsItem = { SystemStatsItem() }
    public var ejectDrive: @MainActor (URL) -> Void = { _ in }
    public var openURL: @MainActor (URL) -> Void = { _ in }
    public var pinnedApps: @MainActor () -> [PinnedApp] = { [] }
    public var launchApp: @MainActor (String) -> Void = { _ in }
    public var pinnedShortcuts: @MainActor () -> [PinnedShortcut] = { [] }
    public var addShortcut: @MainActor (String) -> Void = { _ in }
    public var removeShortcut: @MainActor (UUID) -> Void = { _ in }
    public var reminders: @MainActor () -> [QuickReminderItem] = { [] }
    public var addReminder: @MainActor (String) -> Void = { _ in }
    public var toggleReminder: @MainActor (UUID) -> Void = { _ in }
    public var removeReminder: @MainActor (UUID) -> Void = { _ in }
    public var stockQuotes: @MainActor () -> [StockQuote] = { [] }
    public var refreshStocks: @MainActor () -> Void = {}
    public var addStockSymbol: @MainActor (String) -> Void = { _ in }
    public var removeStockSymbol: @MainActor (String) -> Void = { _ in }
    public var aiProviders: @MainActor () -> [AIProviderUsage] = { [] }
    public var pendingApprovals: @MainActor () -> [AgentApprovalRequest] = { [] }
    public var resolveApproval: @MainActor (String, Bool) -> Void = { _, _ in }
    public var focusStreakDays: @MainActor () -> Int = { 0 }
    public var focusLast7Days: @MainActor () -> [FocusDayEntry] = { [] }
    public var timerMascot: @MainActor () -> TimerMascot = { .none }
    public var pillVerticalOffset: @MainActor () -> Double = { 0 }
    public var hideNotchBar: @MainActor () -> Bool = { false }
    public var useGlassCards: @MainActor () -> Bool = { false }
    public var toggleDetachedPopover: @MainActor () -> Void = {}
    public var activeLyricLine: @MainActor (NowPlayingSnapshot) -> String? = { _ in nil }

    public init(
        isKeepAwakeActive: @escaping @MainActor () -> Bool = { false },
        toggleKeepAwake: @escaping @MainActor () -> Void = {},
        activateKeepAwake: @escaping @MainActor (TimeInterval?) -> Void = { _ in },
        isMicMuted: @escaping @MainActor () -> Bool = { false },
        toggleMicMute: @escaping @MainActor () -> Void = {},
        outputDevices: @escaping @MainActor () -> [AudioOutputDeviceItem] = { [] },
        selectOutputDevice: @escaping @MainActor (UInt32) -> Void = { _ in },
        pickColor: @escaping @MainActor () -> Void = {},
        captureScreenRegion: @escaping @MainActor () -> Void = {},
        notes: @escaping @MainActor () -> [QuickNote] = { [] },
        addNote: @escaping @MainActor (String) -> Void = { _ in },
        removeNote: @escaping @MainActor (UUID) -> Void = { _ in },
        clipboardEntries: @escaping @MainActor () -> [ClipboardEntry] = { [] },
        toggleClipboardPin: @escaping @MainActor (UUID) -> Void = { _ in },
        removeClipboardEntry: @escaping @MainActor (UUID) -> Void = { _ in },
        clearUnpinnedClipboard: @escaping @MainActor () -> Void = {},
        snippets: @escaping @MainActor () -> [TextSnippet] = { [] },
        addSnippet: @escaping @MainActor (String, String) -> Void = { _, _ in },
        removeSnippet: @escaping @MainActor (UUID) -> Void = { _ in },
        teleprompterScript: @escaping @MainActor () -> String = { "" },
        setTeleprompterScript: @escaping @MainActor (String) -> Void = { _ in },
        teleprompterSpeed: @escaping @MainActor () -> Double = { 24 },
        setTeleprompterSpeed: @escaping @MainActor (Double) -> Void = { _ in },
        systemStats: @escaping @MainActor () -> SystemStatsItem = { SystemStatsItem() },
        ejectDrive: @escaping @MainActor (URL) -> Void = { _ in },
        openURL: @escaping @MainActor (URL) -> Void = { _ in },
        pinnedApps: @escaping @MainActor () -> [PinnedApp] = { [] },
        launchApp: @escaping @MainActor (String) -> Void = { _ in },
        pinnedShortcuts: @escaping @MainActor () -> [PinnedShortcut] = { [] },
        addShortcut: @escaping @MainActor (String) -> Void = { _ in },
        removeShortcut: @escaping @MainActor (UUID) -> Void = { _ in },
        reminders: @escaping @MainActor () -> [QuickReminderItem] = { [] },
        addReminder: @escaping @MainActor (String) -> Void = { _ in },
        toggleReminder: @escaping @MainActor (UUID) -> Void = { _ in },
        removeReminder: @escaping @MainActor (UUID) -> Void = { _ in },
        stockQuotes: @escaping @MainActor () -> [StockQuote] = { [] },
        refreshStocks: @escaping @MainActor () -> Void = {},
        addStockSymbol: @escaping @MainActor (String) -> Void = { _ in },
        removeStockSymbol: @escaping @MainActor (String) -> Void = { _ in },
        aiProviders: @escaping @MainActor () -> [AIProviderUsage] = { [] },
        pendingApprovals: @escaping @MainActor () -> [AgentApprovalRequest] = { [] },
        resolveApproval: @escaping @MainActor (String, Bool) -> Void = { _, _ in },
        focusStreakDays: @escaping @MainActor () -> Int = { 0 },
        focusLast7Days: @escaping @MainActor () -> [FocusDayEntry] = { [] },
        timerMascot: @escaping @MainActor () -> TimerMascot = { .none },
        pillVerticalOffset: @escaping @MainActor () -> Double = { 0 },
        hideNotchBar: @escaping @MainActor () -> Bool = { false },
        useGlassCards: @escaping @MainActor () -> Bool = { false },
        toggleDetachedPopover: @escaping @MainActor () -> Void = {},
        activeLyricLine: @escaping @MainActor (NowPlayingSnapshot) -> String? = { _ in nil }
    ) {
        self.isKeepAwakeActive = isKeepAwakeActive
        self.toggleKeepAwake = toggleKeepAwake
        self.activateKeepAwake = activateKeepAwake
        self.isMicMuted = isMicMuted
        self.toggleMicMute = toggleMicMute
        self.outputDevices = outputDevices
        self.selectOutputDevice = selectOutputDevice
        self.pickColor = pickColor
        self.captureScreenRegion = captureScreenRegion
        self.notes = notes
        self.addNote = addNote
        self.removeNote = removeNote
        self.clipboardEntries = clipboardEntries
        self.toggleClipboardPin = toggleClipboardPin
        self.removeClipboardEntry = removeClipboardEntry
        self.clearUnpinnedClipboard = clearUnpinnedClipboard
        self.snippets = snippets
        self.addSnippet = addSnippet
        self.removeSnippet = removeSnippet
        self.teleprompterScript = teleprompterScript
        self.setTeleprompterScript = setTeleprompterScript
        self.teleprompterSpeed = teleprompterSpeed
        self.setTeleprompterSpeed = setTeleprompterSpeed
        self.systemStats = systemStats
        self.ejectDrive = ejectDrive
        self.openURL = openURL
        self.pinnedApps = pinnedApps
        self.launchApp = launchApp
        self.pinnedShortcuts = pinnedShortcuts
        self.addShortcut = addShortcut
        self.removeShortcut = removeShortcut
        self.reminders = reminders
        self.addReminder = addReminder
        self.toggleReminder = toggleReminder
        self.removeReminder = removeReminder
        self.stockQuotes = stockQuotes
        self.refreshStocks = refreshStocks
        self.addStockSymbol = addStockSymbol
        self.removeStockSymbol = removeStockSymbol
        self.aiProviders = aiProviders
        self.pendingApprovals = pendingApprovals
        self.resolveApproval = resolveApproval
        self.focusStreakDays = focusStreakDays
        self.focusLast7Days = focusLast7Days
        self.timerMascot = timerMascot
        self.pillVerticalOffset = pillVerticalOffset
        self.hideNotchBar = hideNotchBar
        self.useGlassCards = useGlassCards
        self.toggleDetachedPopover = toggleDetachedPopover
        self.activeLyricLine = activeLyricLine
    }
}

extension EnvironmentValues {
    @Entry public var quickTools = QuickToolsActions()
}
