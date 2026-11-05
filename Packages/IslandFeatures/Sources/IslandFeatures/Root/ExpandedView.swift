import AppKit
import IslandCore
import IslandDesign
import SwiftUI

/// Expanded island: top band beside the camera (hero symbol left, pill tabs and quick tools right), then the page.
struct ExpandedView: View {
    let page: IslandPage
    let layout: IslandLayout
    let home: HomeInputs
    let notch: NotchMetrics
    let send: @MainActor (IslandEvent) -> Void
    let openSettings: @MainActor () -> Void
    @FocusState private var focused: Bool
    @Environment(\.shelfActions) private var shelf
    @Environment(\.quickTools) private var quickTools
    @State private var showsNotesPopover = false
    @State private var showsClipboardPopover = false
    @State private var showsSearchPopover = false
    @State private var showsTeleprompterPopover = false
    @State private var showsStatsPopover = false
    @State private var showsHubPopover = false
    @State private var draftNote = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 6) {
                    topLeadingSymbol
                    headerQuickTools
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Color.clear.frame(width: notch.size.width)
                HStack(spacing: 4) {
                    tab("island.tab.home", .home)
                    tab("island.tab.shelf", .shelf)
                    Button(action: quickTools.toggleDetachedPopover) {
                        Image(systemName: "pip.exit")
                            .font(.system(size: 12, weight: .medium))
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 22, height: 22)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.leading, 2)
                    .accessibilityLabel(Text("tools.detachMenuBar", bundle: .module))
                    Button(action: openSettings) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13, weight: .medium))
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 22, height: 22)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.leading, 2)
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
        let keepAwake = quickTools.isKeepAwakeActive()
        let micMuted = quickTools.isMicMuted()
        let outputs = quickTools.outputDevices()

        HStack(spacing: 2) {
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

            if !outputs.isEmpty {
                Menu {
                    ForEach(outputs) { dev in
                        Button {
                            quickTools.selectOutputDevice(dev.id)
                        } label: {
                            HStack {
                                Text(dev.name)
                                if dev.isCurrent {
                                    Image(systemName: "checkmark")
                                }
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
            }

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

            Button {
                showsNotesPopover.toggle()
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
            .popover(isPresented: $showsNotesPopover) {
                quickNotesPopover
            }

            Button {
                showsClipboardPopover.toggle()
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
            .popover(isPresented: $showsClipboardPopover) {
                ClipboardAndSnippetsPopover()
            }

            Button {
                showsSearchPopover.toggle()
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
            .popover(isPresented: $showsSearchPopover) {
                SearchAndPalettePopover(send: send, openSettings: openSettings)
            }

            Button {
                showsTeleprompterPopover.toggle()
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
            .popover(isPresented: $showsTeleprompterPopover) {
                TeleprompterPopover()
            }

            Button {
                showsStatsPopover.toggle()
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
            .popover(isPresented: $showsStatsPopover) {
                SystemStatsPopover()
            }

            Button {
                showsHubPopover.toggle()
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
            .popover(isPresented: $showsHubPopover) {
                LauncherAndHubPopover()
            }
        }
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
        }
    }

    @ViewBuilder private var content: some View {
        switch page {
        case .home:
            HomePageView(inputs: home).environment(\.islandLayout, layout)
        case .shelf:
            ShelfPage(items: shelf.items())
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
                .font(TypeToken.body.font)
                .foregroundStyle(isActive ? Palette.textPrimary : Palette.textSecondary)
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(isActive ? Palette.inkPressed : .clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
