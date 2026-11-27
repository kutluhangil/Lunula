import AppKit
import IslandCore
import IslandDesign
import SwiftUI

/// Tab 4: Quick tools grid (toggle + drag-to-reorder), Mini AI config, cross-tab jump links, and `lunula://` agent hooks.
struct ToolsSettingsView: View {
    @Bindable var settings: SettingsStore
    var onSelectTab: ((SettingsTabID) -> Void)?
    var hasAIKey: @MainActor (QuickAIProvider) -> Bool
    var saveAIKey: @MainActor (String, QuickAIProvider) -> Void
    var clearAIKey: @MainActor (QuickAIProvider) -> Void

    @State private var copiedIndex: Int?
    @State private var targetedToolKey: String?
    @State private var apiKeyDraft = ""
    @State private var keyStateRevision = 0

    init(
        settings: SettingsStore,
        onSelectTab: ((SettingsTabID) -> Void)? = nil,
        hasAIKey: @escaping @MainActor (QuickAIProvider) -> Bool = { _ in false },
        saveAIKey: @escaping @MainActor (String, QuickAIProvider) -> Void = { _, _ in },
        clearAIKey: @escaping @MainActor (QuickAIProvider) -> Void = { _ in }
    ) {
        self.settings = settings
        self.onSelectTab = onSelectTab
        self.hasAIKey = hasAIKey
        self.saveAIKey = saveAIKey
        self.clearAIKey = clearAIKey
    }

    private struct ToolItem: Identifiable {
        let key: String
        let titleKey: LocalizedStringKey
        let symbol: String
        let hasShortcutBadge: Bool
        var id: String { key }
    }

    private static let catalog: [String: ToolItem] = [
        "awake": ToolItem(
            key: "awake", titleKey: "settings.tools.item.awake", symbol: "cup.and.saucer.fill", hasShortcutBadge: false),
        "mic": ToolItem(
            key: "mic", titleKey: "settings.tools.item.mic", symbol: "mic.slash.fill", hasShortcutBadge: false),
        "out": ToolItem(
            key: "out", titleKey: "settings.tools.item.out", symbol: "speaker.wave.2.fill", hasShortcutBadge: false),
        "drop": ToolItem(
            key: "drop", titleKey: "settings.tools.item.drop", symbol: "eyedropper", hasShortcutBadge: false),
        "notes": ToolItem(
            key: "notes", titleKey: "settings.tools.item.notes", symbol: "note.text", hasShortcutBadge: false),
        "clip": ToolItem(
            key: "clip", titleKey: "settings.tools.item.clip", symbol: "doc.on.clipboard", hasShortcutBadge: false),
        "search": ToolItem(
            key: "search", titleKey: "settings.tools.item.search", symbol: "magnifyingglass", hasShortcutBadge: false),
        "prompt": ToolItem(
            key: "prompt", titleKey: "settings.tools.item.prompt", symbol: "quote.bubble", hasShortcutBadge: false),
        "stats": ToolItem(
            key: "stats", titleKey: "settings.tools.item.stats", symbol: "gauge.with.needle", hasShortcutBadge: false),
        "stocks": ToolItem(
            key: "stocks", titleKey: "settings.tools.item.stocks", symbol: "chart.line.uptrend.xyaxis",
            hasShortcutBadge: false),
        "kbd": ToolItem(
            key: "kbd", titleKey: "settings.tools.item.kbd", symbol: "keyboard", hasShortcutBadge: true),
        "ai": ToolItem(
            key: "ai", titleKey: "settings.tools.item.ai", symbol: "sparkles.rectangle.stack", hasShortcutBadge: false),
        "mirror": ToolItem(
            key: "mirror", titleKey: "settings.tools.item.mirror", symbol: "web.camera", hasShortcutBadge: false),
        "record": ToolItem(
            key: "record", titleKey: "settings.tools.item.record", symbol: "record.circle", hasShortcutBadge: false),
    ]

    private var orderedTools: [ToolItem] {
        QuickToolID.normalizedOrder(settings.settings.quickToolOrder).compactMap { Self.catalog[$0] }
    }

    private let agentURLs: [(url: String, descriptionKey: LocalizedStringKey)] = [
        ("lunula://activity/show", "settings.tools.url.show"),
        ("lunula://ai/usage", "settings.tools.url.aiUsage"),
        ("lunula://agent/approval", "settings.tools.url.approval"),
    ]

    private var retentionText: String {
        switch settings.settings.shelfRetentionDays {
        case nil: String(localized: "settings.shelf.retention.never")
        case 1: String(localized: "settings.shelf.retention.1")
        case 7: String(localized: "settings.shelf.retention.7")
        case 30: String(localized: "settings.shelf.retention.30")
        case let days?: String(localized: "settings.common.days \(days)")
        }
    }

    private let claudeHookSnippet = """
        "hooks": {
          "Notification": [
            { "hooks": [
              { "type": "command",
                "command": "open -g 'lunula://agent/approval'" }
            ] }
          ]
        }
        """

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // MARK: - Section 1: Toolbar tools
            VStack(alignment: .leading, spacing: 8) {
                Text("settings.tools.section.toolbar")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, 4)

                VStack(alignment: .leading, spacing: 10) {
                    Text("settings.tools.toolbar.subtitle")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Palette.textSecondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(orderedTools) { item in
                            let isEnabled = settings.settings.enabledQuickTools.contains(item.key)
                            let isDropTarget = targetedToolKey == item.key
                            Button {
                                toggleTool(item.key)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: item.symbol)
                                        .font(.system(size: 13, weight: .medium))
                                        .frame(width: 16, height: 16)
                                    Text(item.titleKey)
                                        .font(.system(size: 13, weight: .medium))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Spacer(minLength: 0)
                                    if item.hasShortcutBadge {
                                        Text("⌘⎋")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(Palette.textSecondary)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .frame(height: 40)
                                .background(isEnabled ? Palette.inkPressed : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(
                                            isDropTarget
                                                ? Palette.amberGold
                                                : (isEnabled ? Color.white.opacity(0.24) : Color.white.opacity(0.10)),
                                            lineWidth: isDropTarget ? 1.0 : 0.5
                                        )
                                )
                                .foregroundStyle(isEnabled ? Palette.textPrimary : Palette.textSecondary)
                            }
                            .buttonStyle(.plain)
                            .draggable(item.key)
                            .dropDestination(for: String.self) { dropped, _ in
                                guard let draggedKey = dropped.first else { return false }
                                return moveTool(draggedKey, to: item.key)
                            } isTargeted: { targeted in
                                targetedToolKey =
                                    targeted ? item.key : (targetedToolKey == item.key ? nil : targetedToolKey)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Palette.inkRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.hairlineContrast, lineWidth: 0.5)
                )
            }

            // MARK: - Section 2: Mini AI (Ollama & BYOK)
            miniAISection

            // MARK: - Section 3: Links to other tabs
            VStack(alignment: .leading, spacing: 8) {
                Text("settings.tools.section.otherTabs")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    crossTabRow(
                        titleKey: "settings.appearance.doubleTapOption",
                        pathKey: "settings.tools.jump.doubleTap.path",
                        value: String(
                            localized: settings.settings.doubleTapOptionToToggle
                                ? "settings.common.on" : "settings.common.off"),
                        targetTab: .general
                    )
                    Divider().overlay(Color.white.opacity(0.08))
                    crossTabRow(
                        titleKey: "settings.appearance.fullChargeThreshold",
                        pathKey: "settings.tools.jump.charge.path",
                        value: "\(settings.settings.fullChargeThreshold)%",
                        targetTab: .activities
                    )
                    Divider().overlay(Color.white.opacity(0.08))
                    crossTabRow(
                        titleKey: "settings.tools.jump.shelf.title",
                        pathKey: "settings.tools.jump.shelf.path",
                        value: retentionText,
                        targetTab: .activities
                    )
                }
                .background(Palette.inkRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.hairlineContrast, lineWidth: 0.5)
                )
            }

            // MARK: - Section 3: lunula:// and Agent Hooks
            VStack(alignment: .leading, spacing: 8) {
                Text("settings.tools.section.hooks")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, 4)

                VStack(alignment: .leading, spacing: 10) {
                    VStack(spacing: 0) {
                        ForEach(Array(agentURLs.enumerated()), id: \.offset) { index, item in
                            if index > 0 {
                                Divider().overlay(Color.white.opacity(0.08))
                            }
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.url)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(Palette.textPrimary)
                                    Text(item.descriptionKey)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(Palette.textSecondary)
                                }
                                Spacer()
                                Button {
                                    copyToClipboard(text: item.url, index: index)
                                } label: {
                                    Text(copiedIndex == index ? "settings.tools.copied" : "settings.tools.copy")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(
                                            copiedIndex == index ? Palette.signalGreen : Palette.textPrimary
                                        )
                                        .padding(.horizontal, 10)
                                        .frame(height: 24)
                                        .background(Palette.inkPressed)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                    }
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
                    )

                    Text("settings.tools.claudeHookCaption")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Palette.textSecondary)

                    Text(claudeHookSnippet)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Palette.textPrimary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
                        )
                }
                .padding(12)
                .background(Palette.inkRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.hairlineContrast, lineWidth: 0.5)
                )
            }
        }
    }

    private var miniAISection: some View {
        let provider = settings.settings.quickAIConfig.provider
        let _ = keyStateRevision
        let keySaved = hasAIKey(provider)

        return VStack(alignment: .leading, spacing: 8) {
            Text("settings.tools.section.ai")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("settings.tools.ai.provider")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Palette.textPrimary)
                        Text("settings.tools.ai.provider.subtitle")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Palette.textSecondary)
                    }
                    Spacer()
                    LunulaSegmentPicker(
                        selection: Binding(
                            get: { settings.settings.quickAIConfig.provider },
                            set: { selected in
                                apiKeyDraft = ""
                                settings.update { $0.quickAIConfig.provider = selected }
                            }
                        ),
                        items: [
                            (value: QuickAIProvider.ollama, label: "Ollama"),
                            (value: QuickAIProvider.openAI, label: "OpenAI"),
                            (value: QuickAIProvider.anthropic, label: "Anthropic"),
                            (value: QuickAIProvider.gemini, label: "Gemini"),
                        ]
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                Divider().overlay(Color.white.opacity(0.08))

                HStack(spacing: 12) {
                    Text("settings.tools.ai.model")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.textPrimary)
                    Spacer()
                    TextField(
                        provider.defaultModel,
                        text: Binding(
                            get: { settings.settings.quickAIConfig.model },
                            set: { model in settings.update { $0.quickAIConfig.model = model } }
                        )
                    )
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, 10)
                    .frame(width: 240, height: 28)
                    .background(Palette.obsidian)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Palette.hairline, lineWidth: 0.5)
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                Divider().overlay(Color.white.opacity(0.08))

                if provider == .ollama {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.tools.ai.ollamaEndpoint")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Palette.textPrimary)
                            Text("settings.tools.ai.ollamaEndpoint.subtitle")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Palette.textSecondary)
                        }
                        Spacer()
                        TextField(
                            "http://127.0.0.1:11434",
                            text: Binding(
                                get: { settings.settings.quickAIConfig.ollamaEndpoint },
                                set: { endpoint in
                                    settings.update { $0.quickAIConfig.ollamaEndpoint = endpoint }
                                }
                            )
                        )
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Palette.textPrimary)
                        .padding(.horizontal, 10)
                        .frame(width: 240, height: 28)
                        .background(Palette.obsidian)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Palette.hairline, lineWidth: 0.5)
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }

                if provider.requiresAPIKey {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text("settings.tools.ai.apiKey")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Palette.textPrimary)

                            Spacer()

                            if keySaved {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text("settings.tools.ai.keySaved")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundStyle(Palette.signalGreen)
                            }
                        }

                        HStack(spacing: 8) {
                            SecureField(String(localized: "settings.tools.ai.apiKey.placeholder"), text: $apiKeyDraft)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Palette.textPrimary)
                                .padding(.horizontal, 10)
                                .frame(height: 28)
                                .background(Palette.obsidian)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Palette.hairline, lineWidth: 0.5)
                                )
                                .onSubmit {
                                    commitAIKey(for: provider)
                                }

                            Button {
                                commitAIKey(for: provider)
                            } label: {
                                Text("settings.tools.ai.saveKey")
                            }
                            .buttonStyle(.lunulaSecondary)
                            .disabled(apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                            Button {
                                clearAIKey(provider)
                                apiKeyDraft = ""
                                keyStateRevision &+= 1
                            } label: {
                                Text("settings.tools.ai.clearKey")
                            }
                            .buttonStyle(.lunulaSecondary)
                            .disabled(!keySaved)
                        }

                        Text("settings.tools.ai.keyNote")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Palette.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
            }
            .background(Palette.inkRaised)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Palette.hairlineContrast, lineWidth: 0.5)
            )
        }
    }

    private func commitAIKey(for provider: QuickAIProvider) {
        let trimmed = apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        saveAIKey(trimmed, provider)
        apiKeyDraft = ""
        keyStateRevision &+= 1
    }

    private func crossTabRow(
        titleKey: LocalizedStringKey, pathKey: LocalizedStringKey, value: String, targetTab: SettingsTabID
    ) -> some View {
        Button {
            onSelectTab?(targetTab)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(titleKey)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.textPrimary)
                    Text(pathKey)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer()
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Palette.textSecondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Palette.textSecondary)
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toggleTool(_ key: String) {
        settings.update { s in
            if s.enabledQuickTools.contains(key) {
                s.enabledQuickTools.remove(key)
            } else {
                s.enabledQuickTools.insert(key)
            }
        }
    }

    private func moveTool(_ draggedKey: String, to targetKey: String) -> Bool {
        guard draggedKey != targetKey else { return false }
        var order = QuickToolID.normalizedOrder(settings.settings.quickToolOrder)
        guard let from = order.firstIndex(of: draggedKey), let to = order.firstIndex(of: targetKey) else {
            return false
        }
        let item = order.remove(at: from)
        order.insert(item, at: to)
        settings.update { $0.quickToolOrder = order }
        return true
    }

    private func copyToClipboard(text: String, index: Int) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        withAnimation {
            copiedIndex = index
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if copiedIndex == index {
                withAnimation {
                    copiedIndex = nil
                }
            }
        }
    }
}
