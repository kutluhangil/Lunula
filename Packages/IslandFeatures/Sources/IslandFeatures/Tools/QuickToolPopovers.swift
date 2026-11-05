import AppKit
import IslandCore
import IslandDesign
import SwiftUI

struct ClipboardAndSnippetsPopover: View {
    @Environment(\.quickTools) private var quickTools
    @State private var searchQuery = ""
    @State private var showingSnippets = false
    @State private var newSnippetTitle = ""
    @State private var newSnippetBody = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Button {
                    showingSnippets = false
                } label: {
                    Text("tools.clipboard", bundle: .module)
                        .font(TypeToken.caption.font)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(!showingSnippets ? Palette.inkPressed : .clear, in: Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    showingSnippets = true
                } label: {
                    Text("tools.snippets", bundle: .module)
                        .font(TypeToken.caption.font)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(showingSnippets ? Palette.inkPressed : .clear, in: Capsule())
                }
                .buttonStyle(.plain)

                Spacer()
                if !showingSnippets {
                    Button(action: quickTools.clearUnpinnedClipboard) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("tools.clipboard.clear", bundle: .module))
                }
            }

            if showingSnippets {
                snippetsView
            } else {
                clipboardView
            }
        }
        .padding(10)
        .frame(width: 280)
    }

    private var clipboardView: some View {
        let all = quickTools.clipboardEntries()
        let filtered =
            searchQuery.isEmpty
            ? all
            : all.filter { $0.text.localizedCaseInsensitiveContains(searchQuery) }
        return VStack(alignment: .leading, spacing: 6) {
            TextField(String(localized: "tools.clipboard.search", bundle: .module), text: $searchQuery)
                .textFieldStyle(.roundedBorder)
            if filtered.isEmpty {
                Text("tools.clipboard.empty", bundle: .module)
                    .font(TypeToken.caption.font)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(filtered) { entry in
                            HStack(spacing: 6) {
                                smartBadge(for: entry.smartKind)
                                Text(entry.text)
                                    .font(TypeToken.caption.font)
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Button {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(entry.text, forType: .string)
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 11))
                                }
                                .buttonStyle(.plain)
                                Button {
                                    quickTools.toggleClipboardPin(entry.id)
                                } label: {
                                    Image(systemName: entry.isPinned ? "pin.fill" : "pin")
                                        .font(.system(size: 11))
                                        .foregroundStyle(entry.isPinned ? Palette.signalOrange : .secondary)
                                }
                                .buttonStyle(.plain)
                                Button {
                                    quickTools.removeClipboardEntry(entry.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(maxHeight: 160)
            }
        }
    }

    @ViewBuilder private func smartBadge(for kind: ClipboardSmartKind) -> some View {
        switch kind {
        case .plainText:
            EmptyView()
        case .url(let url):
            Button {
                quickTools.openURL(url)
            } label: {
                Image(systemName: "safari")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.signalGreen)
            }
            .buttonStyle(.plain)
        case .email(let email):
            Button {
                if let url = URL(string: "mailto:\(email)") {
                    quickTools.openURL(url)
                }
            } label: {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.signalOrange)
            }
            .buttonStyle(.plain)
        case .hexColor(let color):
            Circle()
                .fill(Palette.color(color))
                .frame(width: 10, height: 10)
        }
    }

    private var snippetsView: some View {
        let list = quickTools.snippets()
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                TextField(String(localized: "tools.snippets.title", bundle: .module), text: $newSnippetTitle)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                TextField(String(localized: "tools.snippets.body", bundle: .module), text: $newSnippetBody)
                    .textFieldStyle(.roundedBorder)
                Button {
                    quickTools.addSnippet(newSnippetTitle, newSnippetBody)
                    newSnippetTitle = ""
                    newSnippetBody = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
            }
            if list.isEmpty {
                Text("tools.snippets.empty", bundle: .module)
                    .font(TypeToken.caption.font)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(list) { snippet in
                            HStack(spacing: 6) {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(snippet.title)
                                        .font(TypeToken.caption.font)
                                        .fontWeight(.semibold)
                                    Text(snippet.body)
                                        .font(TypeToken.caption.font)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Button {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(snippet.body, forType: .string)
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 11))
                                }
                                .buttonStyle(.plain)
                                Button {
                                    quickTools.removeSnippet(snippet.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(maxHeight: 150)
            }
        }
    }
}

struct SearchAndPalettePopover: View {
    let send: @MainActor (IslandEvent) -> Void
    let openSettings: @MainActor () -> Void
    @Environment(\.quickTools) private var quickTools
    @Environment(\.timerActions) private var timerActions
    @State private var query = ""
    @State private var engine: SearchEngine = .google

    var body: some View {
        let evaluated = QuickExpressionEvaluator.evaluate(query)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                TextField(String(localized: "tools.search.placeholder", bundle: .module), text: $query)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        if let url = engine.searchURL(for: query) {
                            quickTools.openURL(url)
                        }
                    }
                Picker("", selection: $engine) {
                    ForEach(SearchEngine.allCases, id: \.self) { item in
                        Text(item.displayName).tag(item)
                    }
                }
                .labelsHidden()
                .frame(width: 96)
            }

            if let evaluated {
                let formatted = QuickExpressionEvaluator.format(evaluated)
                HStack {
                    Text("= \(formatted)")
                        .font(TypeToken.title.font)
                        .monospacedDigit()
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(formatted, forType: .string)
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                }
                .padding(6)
                .background(Palette.inkPressed, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Divider()
            Text("tools.palette.commands", bundle: .module)
                .font(TypeToken.caption.font)
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    paletteButton("house", "island.tab.home") { send(.pageSelected(.home)) }
                    paletteButton("tray", "island.tab.shelf") { send(.pageSelected(.shelf)) }
                    paletteButton("cup.and.saucer.fill", "tools.keepAwake", quickTools.toggleKeepAwake)
                    paletteButton("mic.slash.fill", "tools.micMute", quickTools.toggleMicMute)
                    paletteButton("timer", "timer.pomodoro", timerActions.startPomodoro)
                    paletteButton("stopwatch", "timer.stopwatch", timerActions.startStopwatch)
                    paletteButton("eyedropper", "tools.eyedropper", quickTools.pickColor)
                    paletteButton("gearshape", "a11y.openSettings", openSettings)
                }
            }
            .frame(maxHeight: 140)
        }
        .padding(10)
        .frame(width: 300)
    }

    private func paletteButton(
        _ symbol: String, _ titleKey: LocalizedStringKey, _ action: @escaping @MainActor () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .medium))
                    .frame(width: 16)
                Text(titleKey, bundle: .module)
                    .font(TypeToken.caption.font)
                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct TeleprompterPopover: View {
    @Environment(\.quickTools) private var quickTools
    @State private var scriptText = ""
    @State private var isScrolling = false
    @State private var scrollStartDate: Date?
    @State private var speed = 24.0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label {
                    Text("tools.teleprompter", bundle: .module)
                } icon: {
                    Image(systemName: "text.aligncenter")
                }
                .font(TypeToken.caption.font)
                Spacer()
                Button {
                    if isScrolling {
                        isScrolling = false
                        scrollStartDate = nil
                    } else {
                        scrollStartDate = Date()
                        isScrolling = true
                    }
                } label: {
                    Image(systemName: isScrolling ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.plain)
            }

            if isScrolling, let start = scrollStartDate {
                TimelineView(.animation) { context in
                    let elapsed = max(0, context.date.timeIntervalSince(start))
                    let offset = CGFloat(elapsed * speed)
                    ScrollView {
                        Text(scriptText.isEmpty ? "…" : scriptText)
                            .font(TypeToken.title.font)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .offset(y: -offset)
                    }
                    .frame(height: 110)
                }
            } else {
                TextEditor(text: $scriptText)
                    .font(TypeToken.body.font)
                    .frame(height: 110)
                    .onChange(of: scriptText) { _, newValue in
                        quickTools.setTeleprompterScript(newValue)
                    }
            }

            HStack(spacing: 6) {
                Image(systemName: "tortoise")
                    .font(.system(size: 10))
                Slider(value: $speed, in: 10...80)
                    .onChange(of: speed) { _, newValue in
                        quickTools.setTeleprompterSpeed(newValue)
                    }
                Image(systemName: "hare")
                    .font(.system(size: 10))
            }
        }
        .padding(10)
        .frame(width: 280)
        .onAppear {
            scriptText = quickTools.teleprompterScript()
            speed = quickTools.teleprompterSpeed()
        }
    }
}

struct SystemStatsPopover: View {
    @Environment(\.quickTools) private var quickTools

    var body: some View {
        let stats = quickTools.systemStats()
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CPU")
                        .font(TypeToken.caption.font)
                        .foregroundStyle(.secondary)
                    Text("\(stats.cpuPercent)%")
                        .font(TypeToken.title.font)
                        .monospacedDigit()
                }
                Divider().frame(height: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("RAM")
                        .font(TypeToken.caption.font)
                        .foregroundStyle(.secondary)
                    Text(
                        String(
                            format: "%.1f / %.0f GB (%d%%)",
                            stats.memoryUsedGB, stats.memoryTotalGB, stats.memoryPercent)
                    )
                    .font(TypeToken.title.font)
                    .monospacedDigit()
                }
            }

            if !stats.wirelessBatteries.isEmpty {
                Divider()
                Text("tools.stats.devices", bundle: .module)
                    .font(TypeToken.caption.font)
                    .foregroundStyle(.secondary)
                ForEach(stats.wirelessBatteries) { dev in
                    HStack {
                        Image(systemName: "wave.3.right")
                            .font(.system(size: 10))
                        Text(dev.name)
                            .font(TypeToken.caption.font)
                            .lineLimit(1)
                        Spacer()
                        Text("\(dev.level)%")
                            .font(TypeToken.caption.font)
                            .monospacedDigit()
                    }
                }
            }

            if !stats.mountedDrives.isEmpty {
                Divider()
                Text("tools.stats.drives", bundle: .module)
                    .font(TypeToken.caption.font)
                    .foregroundStyle(.secondary)
                ForEach(stats.mountedDrives) { drive in
                    HStack {
                        Image(systemName: "externaldrive.fill")
                            .font(.system(size: 11))
                        Text(drive.name)
                            .font(TypeToken.caption.font)
                            .lineLimit(1)
                        Spacer()
                        Button {
                            quickTools.ejectDrive(drive.url)
                        } label: {
                            Image(systemName: "eject.fill")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("tools.stats.eject", bundle: .module))
                    }
                }
            }

            let streak = quickTools.focusStreakDays()
            let focusDays = quickTools.focusLast7Days()
            if streak > 0 || focusDays.contains(where: { $0.minutes > 0 }) {
                Divider()
                HStack {
                    Text("tools.focus.streak \(streak)", bundle: .module)
                        .font(TypeToken.caption.font)
                    Spacer()
                }
                HStack(alignment: .bottom, spacing: 6) {
                    let maxMins = max(focusDays.map(\.minutes).max() ?? 1, 25)
                    ForEach(focusDays, id: \.dayKey) { day in
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(day.minutes > 0 ? Palette.signalOrange : Palette.inkPressed)
                                .frame(width: 14, height: max(4, CGFloat(day.minutes) / CGFloat(maxMins) * 32))
                        }
                    }
                }
                .frame(height: 36)
            }

            let approvals = quickTools.pendingApprovals()
            if !approvals.isEmpty {
                Divider()
                Text("tools.agent.approvals", bundle: .module)
                    .font(TypeToken.caption.font)
                    .foregroundStyle(Palette.signalOrange)
                ForEach(approvals) { req in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(req.agentName)
                                .font(TypeToken.caption.font)
                                .fontWeight(.semibold)
                            Spacer()
                            Button {
                                quickTools.resolveApproval(req.id, true)
                            } label: {
                                Text("tools.agent.approve", bundle: .module)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Palette.signalGreen, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            Button {
                                quickTools.resolveApproval(req.id, false)
                            } label: {
                                Text("tools.agent.deny", bundle: .module)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Palette.signalRed, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        Text(req.commandSummary)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(6)
                    .background(Palette.inkPressed, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }

            let aiList = quickTools.aiProviders()
            if !aiList.isEmpty {
                Divider()
                Text("tools.ai.usage", bundle: .module)
                    .font(TypeToken.caption.font)
                    .foregroundStyle(.secondary)
                ForEach(aiList) { p in
                    HStack {
                        Text(p.provider)
                            .font(TypeToken.caption.font)
                        Spacer()
                        Text("\(p.tokensUsed) tok · \(p.windowLimitPercent)%")
                            .font(TypeToken.caption.font)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(10)
        .frame(width: 250)
    }
}

/// Standalone menu-bar popover hub ("Menu Bar Detach"): exposes Clipboard, Teleprompter, System/AI, and Launcher
/// outside the notch with a one-click Keep Awake toggle in its header.
public struct DetachedMenuBarHubView: View {
    @Environment(\.quickTools) private var quickTools
    @State private var selectedSection = 0

    public init() {}

    public var body: some View {
        let keepAwake = quickTools.isKeepAwakeActive()
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Lunula")
                    .font(TypeToken.title.font)
                    .foregroundStyle(Palette.textPrimary)
                Spacer()
                Button(action: quickTools.toggleKeepAwake) {
                    HStack(spacing: 4) {
                        Image(systemName: keepAwake ? "cup.and.saucer.fill" : "cup.and.saucer")
                            .font(.system(size: 11, weight: .medium))
                        Text("tools.keepAwake", bundle: .module)
                            .font(TypeToken.caption.font)
                    }
                    .foregroundStyle(keepAwake ? Palette.signalOrange : Palette.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Palette.inkPressed, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)

            Picker("", selection: $selectedSection) {
                Image(systemName: "doc.on.clipboard").tag(0)
                Image(systemName: "text.aligncenter").tag(1)
                Image(systemName: "cpu").tag(2)
                Image(systemName: "square.grid.2x2").tag(3)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 10)

            Group {
                switch selectedSection {
                case 0:
                    ClipboardAndSnippetsPopover()
                case 1:
                    TeleprompterPopover()
                case 2:
                    SystemStatsPopover()
                default:
                    LauncherAndHubPopover()
                }
            }
        }
        .background(Palette.obsidian)
    }
}

struct LauncherAndHubPopover: View {
    @Environment(\.quickTools) private var quickTools
    @State private var tab = 0
    @State private var newShortcut = ""
    @State private var newReminder = ""
    @State private var newSymbol = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("", selection: $tab) {
                Text("tools.hub.apps", bundle: .module).tag(0)
                Text("tools.hub.reminders", bundle: .module).tag(1)
                Text("tools.hub.stocks", bundle: .module).tag(2)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            switch tab {
            case 0:
                launcherSection
            case 1:
                remindersSection
            default:
                stocksSection
            }
        }
        .padding(10)
        .frame(width: 280)
    }

    private var launcherSection: some View {
        let apps = quickTools.pinnedApps()
        let shortcuts = quickTools.pinnedShortcuts()
        return VStack(alignment: .leading, spacing: 6) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 6)], spacing: 6) {
                ForEach(apps) { app in
                    Button {
                        quickTools.launchApp(app.path)
                    } label: {
                        Text(app.name)
                            .font(TypeToken.caption.font)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(Palette.inkPressed, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()
            HStack(spacing: 4) {
                TextField(String(localized: "tools.shortcuts.placeholder", bundle: .module), text: $newShortcut)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(submitShortcut)
                Button(action: submitShortcut) {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
            }
            if !shortcuts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(shortcuts) { sc in
                            HStack(spacing: 4) {
                                Button {
                                    if let url = sc.runURL { quickTools.openURL(url) }
                                } label: {
                                    Label(sc.name, systemImage: "bolt.fill")
                                        .font(TypeToken.caption.font)
                                }
                                .buttonStyle(.plain)
                                Button {
                                    quickTools.removeShortcut(sc.id)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Palette.inkPressed, in: Capsule())
                        }
                    }
                }
            }
        }
    }

    private func submitShortcut() {
        let trimmed = newShortcut.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        quickTools.addShortcut(trimmed)
        newShortcut = ""
    }

    private var remindersSection: some View {
        let items = quickTools.reminders()
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                TextField(String(localized: "tools.reminders.placeholder", bundle: .module), text: $newReminder)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(submitReminder)
                Button(action: submitReminder) {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
            }
            if items.isEmpty {
                Text("tools.reminders.empty", bundle: .module)
                    .font(TypeToken.caption.font)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(items) { item in
                            HStack(spacing: 6) {
                                Button {
                                    quickTools.toggleReminder(item.id)
                                } label: {
                                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(item.isCompleted ? Palette.signalGreen : .secondary)
                                }
                                .buttonStyle(.plain)
                                Text(item.title)
                                    .font(TypeToken.caption.font)
                                    .strikethrough(item.isCompleted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Button {
                                    quickTools.removeReminder(item.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(maxHeight: 140)
            }
        }
    }

    private func submitReminder() {
        let trimmed = newReminder.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        quickTools.addReminder(trimmed)
        newReminder = ""
    }

    private var stocksSection: some View {
        let quotes = quickTools.stockQuotes()
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                TextField("AAPL, NVDA…", text: $newSymbol)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(submitSymbol)
                Button(action: submitSymbol) {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                Button(action: quickTools.refreshStocks) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
            }
            if quotes.isEmpty {
                Text("tools.stocks.empty", bundle: .module)
                    .font(TypeToken.caption.font)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(quotes) { q in
                            HStack {
                                Text(q.symbol)
                                    .font(TypeToken.caption.font)
                                    .fontWeight(.semibold)
                                Text(q.session.rawValue.uppercased())
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%.2f", q.price))
                                    .font(TypeToken.caption.font)
                                    .monospacedDigit()
                                Text(String(format: "%+.2f%%", q.changePercent))
                                    .font(TypeToken.caption.font)
                                    .monospacedDigit()
                                    .foregroundStyle(q.changePercent >= 0 ? Palette.signalGreen : Palette.signalRed)
                                Button {
                                    quickTools.removeStockSymbol(q.symbol)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(maxHeight: 140)
            }
        }
        .onAppear(perform: quickTools.refreshStocks)
    }

    private func submitSymbol() {
        let trimmed = newSymbol.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        quickTools.addStockSymbol(trimmed)
        newSymbol = ""
        quickTools.refreshStocks()
    }
}
