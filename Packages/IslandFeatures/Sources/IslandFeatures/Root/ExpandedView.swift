import AppKit
import IslandCore
import IslandDesign
import SwiftUI

enum ActiveToolPopover: String, Identifiable {
    case notes, clipboard, search, teleprompter, stats, hub, ai, mirror
    var id: String { rawValue }
}

/// Expanded island: top band beside the camera (hero symbol left, pill tabs and quick tools right), then the page.
struct ExpandedView: View {
    let page: IslandPage
    let layout: IslandLayout
    let home: HomeInputs
    let notch: NotchMetrics
    var expandedWidth: CGFloat = IslandSurface.expandedWidth
    let send: @MainActor (IslandEvent) -> Void
    let openSettings: @MainActor () -> Void
    @FocusState private var focused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.shelfActions) private var shelf
    @Environment(\.quickTools) private var quickTools
    @State private var activePopover: ActiveToolPopover?
    @State private var showsOverflowPopover = false
    @State private var draftNote = ""

    private var hasLeadingSymbol: Bool {
        layout.primary != nil || page == .shelf || page == .tools
    }

    /// Computes how many 22 pt tool buttons fit inside the left wing without colliding with the notch camera.
    static func maxInlineToolSlots(
        notchWidth: CGFloat, hasLeadingSymbol: Bool, expandedWidth: CGFloat = IslandSurface.expandedWidth
    ) -> Int {
        let wing = (expandedWidth - 2 * Spacing.expandedPadding - notchWidth) / 2
        let reserved: CGFloat = hasLeadingSymbol ? 22 : 0
        return max(1, Int((wing - reserved) / 24))
    }

    /// Splits enabled tools into inline buttons and overflow menu items so the left wing never overflows.
    static func partitionQuickTools(_ enabled: [String], maxSlots: Int) -> (inline: [String], overflow: [String]) {
        guard maxSlots > 0 else { return ([], enabled) }
        if enabled.count <= maxSlots { return (enabled, []) }
        let inlineCount = max(0, maxSlots - 1)
        return (Array(enabled.prefix(inlineCount)), Array(enabled.dropFirst(inlineCount)))
    }

    var body: some View {
        let style = quickTools.visualStyle()
        let isAlcoveMinimal = style == .alcove && layout.primary != nil && page == .home

        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 6) {
                    topLeadingSymbol
                    if !isAlcoveMinimal {
                        headerQuickTools
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .popover(item: $activePopover) { tool in
                    toolPopoverContent(for: tool)
                }

                Color.clear.frame(width: notch.size.width)

                HStack(spacing: 2) {
                    if !isAlcoveMinimal {
                        tab("island.tab.home", .home)
                        tab("island.tab.shelf", .shelf)
                        tab("island.tab.tools", .tools)

                        if style == .boring {
                            Button {
                                activePopover = activePopover == .mirror ? nil : .mirror
                            } label: {
                                Image(systemName: "web.camera")
                                    .font(.system(size: 12, weight: .medium))
                                    .symbolRenderingMode(.hierarchical)
                                    .frame(width: 20, height: 22)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(activePopover == .mirror ? Palette.textPrimary : Palette.textSecondary)
                            .accessibilityLabel(Text("tools.mirror", bundle: .module))
                        }
                    }

                    Button(action: openSettings) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12, weight: .medium))
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 20, height: 22)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Palette.textSecondary)
                    .accessibilityLabel(Text(AccessibilityLabels.openSettings))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(height: notch.size.height)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, Spacing.expandedPadding)
        }
        .padding(.horizontal, Spacing.expandedPadding)
        .padding(.bottom, Spacing.expandedPadding)
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onAppear { focused = true }
        .onKeyPress(.escape) {
            send(.escapePressed)
            return .handled
        }
        .onKeyPress(.leftArrow) {
            send(.pageSelected(PageCycler.previous(before: page)))
            return .handled
        }
        .onKeyPress(.rightArrow) {
            send(.pageSelected(PageCycler.next(after: page)))
            return .handled
        }
    }

    @ViewBuilder private var headerQuickTools: some View {
        let style = quickTools.visualStyle()
        let outputs = quickTools.outputDevices()
        let enabled = quickTools.enabledQuickTools().filter { key in
            key != QuickToolID.out.rawValue || !outputs.isEmpty
        }
        let slots = Self.maxInlineToolSlots(
            notchWidth: notch.size.width, hasLeadingSymbol: hasLeadingSymbol, expandedWidth: expandedWidth)
        let partition = Self.partitionQuickTools(enabled, maxSlots: slots)
        let inlineKeys = style == .lunula ? Array(enabled.prefix(2)) : partition.inline
        let overflowKeys = style == .lunula ? [] : partition.overflow

        HStack(spacing: 2) {
            ForEach(inlineKeys, id: \.self) { key in
                inlineToolButton(for: key, outputs: outputs)
            }

            if !overflowKeys.isEmpty {
                Button {
                    showsOverflowPopover.toggle()
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 12, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.textSecondary)
                .accessibilityLabel(Text("tools.more", bundle: .module))
                .popover(isPresented: $showsOverflowPopover) {
                    overflowToolsPopover(keys: overflowKeys, outputs: outputs)
                }
            }
        }
    }

    @ViewBuilder
    private func toolPopoverContent(for tool: ActiveToolPopover) -> some View {
        switch tool {
        case .notes:
            quickNotesPopover
        case .clipboard:
            ClipboardAndSnippetsPopover()
        case .search:
            SearchAndPalettePopover(send: send, openSettings: openSettings)
        case .teleprompter:
            TeleprompterPopover()
        case .stats:
            SystemStatsPopover()
        case .hub:
            LauncherAndHubPopover()
        case .ai:
            QuickAIPopover()
        case .mirror:
            CameraMirrorPopoverView(
                isAuthorized: quickTools.isMirrorAuthorized(),
                isDenied: quickTools.isMirrorDenied(),
                startPreview: quickTools.startMirrorPreview,
                stopPreview: quickTools.stopMirrorPreview,
                openSystemSettings: {
                    if let url = URL(
                        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
                    ) {
                        quickTools.openURL(url)
                    }
                }
            )
        }
    }

    @ViewBuilder
    private func inlineToolButton(for key: String, outputs: [AudioOutputDeviceItem]) -> some View {
        let keepAwake = quickTools.isKeepAwakeActive()
        let micMuted = quickTools.isMicMuted()

        switch key {
        case QuickToolID.awake.rawValue:
            Button(action: quickTools.toggleKeepAwake) {
                Image(systemName: keepAwake ? "cup.and.saucer.fill" : "cup.and.saucer")
                    .font(.system(size: 12, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(keepAwake ? Palette.signalOrange : Palette.textSecondary)
            .accessibilityLabel(Text("tools.keepAwake", bundle: .module))
            .contextMenu {
                Button {
                    quickTools.activateKeepAwake(nil)
                } label: {
                    Text("tools.keepAwake.indefinite", bundle: .module)
                }
                Button {
                    quickTools.activateKeepAwake(1800)
                } label: {
                    Text("tools.keepAwake.30m", bundle: .module)
                }
                Button {
                    quickTools.activateKeepAwake(3600)
                } label: {
                    Text("tools.keepAwake.1h", bundle: .module)
                }
                Button {
                    quickTools.activateKeepAwake(7200)
                } label: {
                    Text("tools.keepAwake.2h", bundle: .module)
                }
                if keepAwake {
                    Divider()
                    Button {
                        quickTools.toggleKeepAwake()
                    } label: {
                        Text("tools.keepAwake.off", bundle: .module)
                    }
                }
            }

        case QuickToolID.mic.rawValue:
            Button(action: quickTools.toggleMicMute) {
                Image(systemName: micMuted ? "mic.slash.fill" : "mic.fill")
                    .font(.system(size: 12, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(micMuted ? Palette.signalRed : Palette.textSecondary)
            .accessibilityLabel(Text("tools.micMute", bundle: .module))

        case QuickToolID.out.rawValue:
            Menu {
                ForEach(outputs) { dev in
                    Button {
                        quickTools.selectOutputDevice(dev.id)
                    } label: {
                        HStack {
                            Text(dev.name)
                            if dev.isCurrent { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 12, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 22, height: 22)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .foregroundStyle(Palette.textSecondary)
            .accessibilityLabel(Text("tools.audioOutput", bundle: .module))

        case QuickToolID.drop.rawValue:
            Button(action: quickTools.pickColor) {
                Image(systemName: "eyedropper")
                    .font(.system(size: 12, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.textSecondary)
            .accessibilityLabel(Text("tools.eyedropper", bundle: .module))

        case QuickToolID.notes.rawValue:
            Button {
                activePopover = activePopover == .notes ? nil : .notes
            } label: {
                Image(systemName: "note.text")
                    .font(.system(size: 12, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(quickTools.notes().isEmpty ? Palette.textSecondary : Palette.textPrimary)
            .accessibilityLabel(Text("tools.quickNotes", bundle: .module))

        case QuickToolID.clip.rawValue:
            Button {
                activePopover = activePopover == .clipboard ? nil : .clipboard
            } label: {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 12, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.textSecondary)
            .accessibilityLabel(Text("tools.clipboard", bundle: .module))

        case QuickToolID.search.rawValue:
            Button {
                activePopover = activePopover == .search ? nil : .search
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.textSecondary)
            .accessibilityLabel(Text("tools.search", bundle: .module))

        case QuickToolID.prompt.rawValue:
            Button {
                activePopover = activePopover == .teleprompter ? nil : .teleprompter
            } label: {
                Image(systemName: "text.aligncenter")
                    .font(.system(size: 12, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.textSecondary)
            .accessibilityLabel(Text("tools.teleprompter", bundle: .module))

        case QuickToolID.stats.rawValue:
            Button {
                activePopover = activePopover == .stats ? nil : .stats
            } label: {
                Image(systemName: "cpu")
                    .font(.system(size: 12, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.textSecondary)
            .accessibilityLabel(Text("tools.stats", bundle: .module))

        case QuickToolID.stocks.rawValue:
            Button {
                activePopover = activePopover == .hub ? nil : .hub
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 12, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.textSecondary)
            .accessibilityLabel(Text("tools.hub.apps", bundle: .module))

        case QuickToolID.kbd.rawValue:
            Button(action: quickTools.startKeyboardCleaningLock) {
                Image(systemName: "keyboard")
                    .font(.system(size: 12, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.textSecondary)
            .accessibilityLabel(Text("tools.keyboardLock", bundle: .module))

        case QuickToolID.ai.rawValue:
            Button {
                activePopover = activePopover == .ai ? nil : .ai
            } label: {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(activePopover == .ai ? Palette.amberGold : Palette.textSecondary)
            .accessibilityLabel(Text("tools.ai", bundle: .module))

        case QuickToolID.mirror.rawValue:
            Button {
                activePopover = activePopover == .mirror ? nil : .mirror
            } label: {
                Image(systemName: "web.camera")
                    .font(.system(size: 12, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(activePopover == .mirror ? Palette.textPrimary : Palette.textSecondary)
            .accessibilityLabel(Text("tools.mirror", bundle: .module))

        case QuickToolID.record.rawValue:
            if quickTools.isScreenRecording() {
                Button(action: quickTools.stopScreenRecording) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion)
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.signalRed)
                .accessibilityLabel(Text("tools.record.stop", bundle: .module))
            } else {
                Menu {
                    Button {
                        quickTools.startScreenRecording(false)
                    } label: {
                        Text("tools.record.mp4", bundle: .module)
                    }
                    Button {
                        quickTools.startScreenRecording(true)
                    } label: {
                        Text("tools.record.gif", bundle: .module)
                    }
                } label: {
                    Image(systemName: "record.circle")
                        .font(.system(size: 12, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 22, height: 22)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .foregroundStyle(Palette.textSecondary)
                .accessibilityLabel(Text("tools.record", bundle: .module))
            }

        default:
            EmptyView()
        }
    }

    private func overflowToolsPopover(keys: [String], outputs: [AudioOutputDeviceItem]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(keys, id: \.self) { key in
                overflowToolRow(for: key, outputs: outputs)
            }
        }
        .padding(8)
        .frame(width: 210)
    }

    @ViewBuilder
    private func overflowToolRow(for key: String, outputs: [AudioOutputDeviceItem]) -> some View {
        switch key {
        case QuickToolID.awake.rawValue:
            overflowButton(
                symbol: quickTools.isKeepAwakeActive() ? "cup.and.saucer.fill" : "cup.and.saucer",
                key: "tools.keepAwake",
                tint: quickTools.isKeepAwakeActive() ? Palette.signalOrange : Palette.textPrimary
            ) {
                showsOverflowPopover = false
                quickTools.toggleKeepAwake()
            }
        case QuickToolID.mic.rawValue:
            overflowButton(
                symbol: quickTools.isMicMuted() ? "mic.slash.fill" : "mic.fill",
                key: "tools.micMute",
                tint: quickTools.isMicMuted() ? Palette.signalRed : Palette.textPrimary
            ) {
                showsOverflowPopover = false
                quickTools.toggleMicMute()
            }
        case QuickToolID.out.rawValue:
            Menu {
                ForEach(outputs) { dev in
                    Button {
                        showsOverflowPopover = false
                        quickTools.selectOutputDevice(dev.id)
                    } label: {
                        HStack {
                            Text(dev.name)
                            if dev.isCurrent { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2.fill").frame(width: 16)
                    Text("tools.audioOutput", bundle: .module)
                        .font(TypeToken.caption.font)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
            }
            .menuStyle(.borderlessButton)
        case QuickToolID.drop.rawValue:
            overflowButton(symbol: "eyedropper", key: "tools.eyedropper") {
                showsOverflowPopover = false
                quickTools.pickColor()
            }
        case QuickToolID.notes.rawValue:
            overflowButton(symbol: "note.text", key: "tools.quickNotes") { openFromOverflow(.notes) }
        case QuickToolID.clip.rawValue:
            overflowButton(symbol: "doc.on.clipboard", key: "tools.clipboard") { openFromOverflow(.clipboard) }
        case QuickToolID.search.rawValue:
            overflowButton(symbol: "magnifyingglass", key: "tools.search") { openFromOverflow(.search) }
        case QuickToolID.prompt.rawValue:
            overflowButton(symbol: "text.aligncenter", key: "tools.teleprompter") { openFromOverflow(.teleprompter) }
        case QuickToolID.stats.rawValue:
            overflowButton(symbol: "cpu", key: "tools.stats") { openFromOverflow(.stats) }
        case QuickToolID.stocks.rawValue:
            overflowButton(symbol: "square.grid.2x2", key: "tools.hub.apps") { openFromOverflow(.hub) }
        case QuickToolID.kbd.rawValue:
            overflowButton(symbol: "keyboard", key: "tools.keyboardLock") {
                showsOverflowPopover = false
                quickTools.startKeyboardCleaningLock()
            }
        case QuickToolID.ai.rawValue:
            overflowButton(symbol: "sparkles", key: "tools.ai", tint: Palette.amberGold) {
                openFromOverflow(.ai)
            }
        case QuickToolID.mirror.rawValue:
            overflowButton(symbol: "web.camera", key: "tools.mirror") {
                openFromOverflow(.mirror)
            }
        case QuickToolID.record.rawValue:
            if quickTools.isScreenRecording() {
                overflowButton(
                    symbol: "stop.circle.fill",
                    key: "tools.record.stop",
                    tint: Palette.signalRed
                ) {
                    showsOverflowPopover = false
                    quickTools.stopScreenRecording()
                }
            } else {
                Menu {
                    Button {
                        showsOverflowPopover = false
                        quickTools.startScreenRecording(false)
                    } label: {
                        Text("tools.record.mp4", bundle: .module)
                    }
                    Button {
                        showsOverflowPopover = false
                        quickTools.startScreenRecording(true)
                    } label: {
                        Text("tools.record.gif", bundle: .module)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "record.circle").frame(width: 16)
                        Text("tools.record", bundle: .module)
                            .font(TypeToken.caption.font)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                }
                .menuStyle(.borderlessButton)
            }
        default:
            EmptyView()
        }
    }

    private func openFromOverflow(_ tool: ActiveToolPopover) {
        showsOverflowPopover = false
        Task { @MainActor in activePopover = tool }
    }

    private func overflowButton(
        symbol: String, key: LocalizedStringKey, tint: Color = Palette.textPrimary, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 16)
                Text(key, bundle: .module)
                    .font(TypeToken.caption.font)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var quickNotesPopover: some View {
        let notes = quickTools.notes()
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                TextField(String(localized: "tools.quickNotes.placeholder", bundle: .module), text: $draftNote)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(submitDraftNote)
                Button(action: submitDraftNote) {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .disabled(draftNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            if notes.isEmpty {
                Text("tools.quickNotes.empty", bundle: .module)
                    .font(TypeToken.caption.font)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(notes) { note in
                            HStack(alignment: .top, spacing: 8) {
                                Text(note.text)
                                    .font(TypeToken.caption.font)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Button {
                                    quickTools.toggleNotePin(note.id)
                                } label: {
                                    Image(systemName: note.isPinned ? "pin.fill" : "pin")
                                        .font(.system(size: 11))
                                        .foregroundStyle(note.isPinned ? Palette.signalOrange : .secondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(
                                    Text(
                                        note.isPinned ? "tools.quickNotes.unpin" : "tools.quickNotes.pin",
                                        bundle: .module))
                                Button {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(note.text, forType: .string)
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 11))
                                }
                                .buttonStyle(.plain)
                                Button {
                                    quickTools.removeNote(note.id)
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
        .padding(10)
        .frame(width: 240)
    }

    private func submitDraftNote() {
        let trimmed = draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        quickTools.addNote(trimmed)
        draftNote = ""
    }

    @ViewBuilder private var topLeadingSymbol: some View {
        if let primary = layout.primary {
            switch primary.content {
            case .nowPlaying:
                Image(systemName: "waveform")
                    .font(.system(size: 13, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(primary.accent.map(Palette.color) ?? Palette.textPrimary)
                    .frame(width: 16, height: 16)
            case .timer(let timer):
                Image(systemName: timer.phase.symbol)
                    .font(.system(size: 13, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Palette.signalOrange)
                    .frame(width: 16, height: 16)
            case .calendar:
                Image(systemName: "video.fill")
                    .font(.system(size: 13, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Palette.signalOrange)
                    .frame(width: 16, height: 16)
            case .custom(let custom):
                Image(systemName: CustomSymbol.resolve(custom.symbol))
                    .font(.system(size: 13, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(primary.accent.map(Palette.color) ?? Palette.textPrimary)
                    .frame(width: 16, height: 16)
            }
        } else if page == .shelf {
            Image(systemName: "tray")
                .font(.system(size: 13, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Palette.textSecondary)
                .frame(width: 16, height: 16)
        } else if page == .tools {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 13, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Palette.textSecondary)
                .frame(width: 16, height: 16)
        }
    }

    @ViewBuilder private var content: some View {
        switch page {
        case .home:
            HomePageView(inputs: home).environment(\.islandLayout, layout)
        case .shelf:
            ShelfPage(items: shelf.items())
        case .tools:
            ToolsGridPageView { tool in
                activePopover = activePopover == tool ? nil : tool
            }
        case .activity(let id):
            if let activity = layout.activity(id) {
                ActivityContentView(activity: activity, slot: .expanded)
            }
        }
    }

    private func tab(_ key: LocalizedStringKey, _ target: IslandPage) -> some View {
        let isActive = page == target
        return Button {
            send(.pageSelected(target))
        } label: {
            Text(key, bundle: .module)
                .font(TypeToken.caption.font)
                .foregroundStyle(isActive ? Palette.textPrimary : Palette.textSecondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 5)
                .frame(height: 22)
                .background(isActive ? Palette.inkPressed : .clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
