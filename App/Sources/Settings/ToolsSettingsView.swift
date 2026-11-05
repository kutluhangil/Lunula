import AppKit
import IslandCore
import IslandDesign
import SwiftUI

/// Tab 4: Quick tools grid, cross-tab jump links, and `lunula://` agent hooks.
struct ToolsSettingsView: View {
    @Bindable var settings: SettingsStore
    var onSelectTab: ((SettingsTabID) -> Void)?

    @State private var copiedIndex: Int?

    private struct ToolItem: Identifiable {
        let key: String
        let title: String
        let symbol: String
        let hasShortcutBadge: Bool
        var id: String { key }
    }

    private let tools: [ToolItem] = [
        ToolItem(key: "awake", title: "Uyanık Tut", symbol: "cup.and.saucer.fill", hasShortcutBadge: false),
        ToolItem(key: "mic", title: "Mikrofonu sustur", symbol: "mic.slash.fill", hasShortcutBadge: false),
        ToolItem(key: "out", title: "Ses çıkışı", symbol: "speaker.wave.2.fill", hasShortcutBadge: false),
        ToolItem(key: "drop", title: "Renk damlalığı", symbol: "eyedropper", hasShortcutBadge: false),
        ToolItem(key: "notes", title: "Hızlı notlar", symbol: "note.text", hasShortcutBadge: false),
        ToolItem(key: "clip", title: "Pano ve şablonlar", symbol: "doc.on.clipboard", hasShortcutBadge: false),
        ToolItem(key: "search", title: "Ara, hesapla, komut", symbol: "magnifyingglass", hasShortcutBadge: false),
        ToolItem(key: "prompt", title: "Teleprompter", symbol: "quote.bubble", hasShortcutBadge: false),
        ToolItem(key: "stats", title: "Sistem istatistikleri", symbol: "gauge.with.needle", hasShortcutBadge: false),
        ToolItem(
            key: "stocks", title: "Başlatıcı ve Borsa", symbol: "chart.line.uptrend.xyaxis", hasShortcutBadge: false),
        ToolItem(key: "kbd", title: "Klavye temizleme", symbol: "keyboard", hasShortcutBadge: true),
    ]

    private let agentURLs: [(url: String, description: String)] = [
        ("lunula://activity/show", "Özel bir etkinliği adada göster"),
        ("lunula://ai/usage", "AI kullanım limitini kompakt adada göster"),
        ("lunula://agent/approval", "Ajan onayını sor; tam ekranda da görünür"),
    ]

    private var retentionText: String {
        switch settings.settings.shelfRetentionDays {
        case nil: "Asla"
        case 1: "1 gün"
        case 7: "7 gün"
        case 30: "30 gün"
        case let days?: "\(days) gün"
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
                Text("Genişlemiş ada araç çubuğu")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, 4)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Seçili araçlar genişlemiş adanın üst çubuğunda durur. Sıra, sürükleyerek değişir.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Palette.textSecondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(tools) { item in
                            let isEnabled = settings.settings.enabledQuickTools.contains(item.key)
                            Button {
                                toggleTool(item.key)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: item.symbol)
                                        .font(.system(size: 13, weight: .medium))
                                        .frame(width: 16, height: 16)
                                    Text(item.title)
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
                                            isEnabled ? Color.white.opacity(0.24) : Color.white.opacity(0.10),
                                            lineWidth: 0.5
                                        )
                                )
                                .foregroundStyle(isEnabled ? Palette.textPrimary : Palette.textSecondary)
                            }
                            .buttonStyle(.plain)
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

            // MARK: - Section 2: Links to other tabs
            VStack(alignment: .leading, spacing: 8) {
                Text("Diğer sekmelerde")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    crossTabRow(
                        title: "Çift ⌥ ile adayı aç/kapat",
                        path: "Genel › Kısayollar",
                        value: settings.settings.doubleTapOptionToToggle ? "Açık" : "Kapalı",
                        targetTab: .general
                    )
                    Divider().overlay(Color.white.opacity(0.08))
                    crossTabRow(
                        title: "Tam şarj uyarı eşiği",
                        path: "Etkinlikler › Pil uyarıları",
                        value: "%\(settings.settings.fullChargeThreshold)",
                        targetTab: .activities
                    )
                    Divider().overlay(Color.white.opacity(0.08))
                    crossTabRow(
                        title: "Raf saklama süresi",
                        path: "Etkinlikler › Raf",
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
                Text("lunula:// ve ajan kancaları")
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
                                    Text(item.description)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(Palette.textSecondary)
                                }
                                Spacer()
                                Button {
                                    copyToClipboard(text: item.url, index: index)
                                } label: {
                                    Text(copiedIndex == index ? "Kopyalandı" : "Kopyala")
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

                    Text("Claude Code kancası · ~/.claude/settings.json")
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

    private func crossTabRow(title: String, path: String, value: String, targetTab: SettingsTabID) -> some View {
        Button {
            onSelectTab?(targetTab)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.textPrimary)
                    Text(path)
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
