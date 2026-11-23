import Foundation
import IslandCoreTestSupport
import Testing

@testable import IslandCore

@Suite struct SyncedLyricsAndNotesTests {
    @Test func parsesLRCAndFindsActiveLine() {
        let raw = """
            [00:12.50] First line of the song
            [00:18.00] Second line of the song
            [01:02.25] Chorus begins
            """
        let lines = SyncedLyricsParser.parse(raw)
        #expect(lines.count == 3)
        #expect(SyncedLyricsParser.activeLine(in: lines, at: 5.0) == nil)
        #expect(SyncedLyricsParser.activeLine(in: lines, at: 13.0) == "First line of the song")
        #expect(SyncedLyricsParser.activeLine(in: lines, at: 25.0) == "Second line of the song")
        #expect(SyncedLyricsParser.activeLine(in: lines, at: 65.0) == "Chorus begins")
        let pair = SyncedLyricsParser.activeAndNextLines(in: lines, at: 13.0)
        #expect(pair?.active == "First line of the song" && pair?.next == "Second line of the song")
        let lastPair = SyncedLyricsParser.activeAndNextLines(in: lines, at: 65.0)
        #expect(lastPair?.active == "Chorus begins" && lastPair?.next == nil)
    }

    @MainActor @Test func quickNotesAddPinAndRemovePersist() throws {
        let suiteName = "test.quicknotes.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let clock = ManualTime()
        let store = QuickNotesStore(defaults: defaults, time: clock)
        store.add("  Buy espresso beans  ")
        store.add("Check release notes")
        #expect(store.notes.count == 2 && store.notes[0].text == "Check release notes")

        let firstID = store.notes[1].id
        store.togglePin(firstID)
        #expect(store.notes[0].id == firstID && store.notes[0].isPinned)

        // Legacy payload without `isPinned` decodes cleanly as unpinned.
        let legacyJSON = #"[{"id":"00000000-0000-0000-0000-000000000001","text":"Legacy","createdAt":0}]"#
        let decoded = try JSONDecoder().decode([QuickNote].self, from: Data(legacyJSON.utf8))
        #expect(decoded.first?.isPinned == false)

        store.remove(firstID)
        #expect(store.notes.count == 1)
    }

    @MainActor @Test func clipboardDetectsSmartKindsAndPreservesPinsOnClear() {
        let suiteName = "test.clipboard.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let clock = ManualTime()
        let store = ClipboardHistoryStore(defaults: defaults, time: clock)

        store.record("https://apple.com")
        store.record("hello@lunula.app")
        store.record("#FF9F0A")
        store.record("Plain note")
        #expect(store.entries.count == 4)
        #expect(store.entries[0].smartKind == .plainText)
        #expect(store.entries[1].smartKind == .hexColor(RGBAColor(hex: "#FF9F0A")!))
        #expect(store.entries[2].smartKind == .email("hello@lunula.app"))
        #expect(store.entries[3].smartKind == .url(URL(string: "https://apple.com")!))

        let pinnedID = store.entries[1].id
        store.togglePin(pinnedID)
        store.clearUnpinned()
        #expect(store.entries.count == 1 && store.entries.first?.id == pinnedID)

        store.addSnippet(title: "Work Email", body: "kutluhan@lunula.app")
        #expect(store.snippets.count == 1)
        store.removeSnippet(store.snippets[0].id)
        #expect(store.snippets.isEmpty)
    }

    @Test func quickExpressionEvaluatorComputesArithmeticAndBuildsSearchURLs() {
        #expect(QuickExpressionEvaluator.evaluate("(12 + 8) * 2.5 - 10") == 40)
        #expect(QuickExpressionEvaluator.evaluate("100 / 0") == nil)
        #expect(QuickExpressionEvaluator.evaluate("just words") == nil)
        #expect(QuickExpressionEvaluator.format(40.0) == "40")
        #expect(SearchEngine.google.searchURL(for: "swift concurrency")?.host() == "www.google.com")
    }

    @MainActor @Test func teleprompterClampsAndPersistsSpeed() {
        let suiteName = "test.teleprompter.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = TeleprompterStore(defaults: defaults)
        store.script = "Welcome to the keynote"
        store.pointsPerSecond = 120
        #expect(store.pointsPerSecond == 80)
        #expect(TeleprompterStore(defaults: defaults).script == "Welcome to the keynote")
    }

    @MainActor @Test func launcherRemindersStocksFocusAndAIUsageStoresWork() {
        let suiteName = "test.wave3.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let clock = ManualTime()

        let launcher = AppLauncherStore(defaults: defaults)
        #expect(!launcher.apps.isEmpty)
        launcher.addApp(name: "Safari", path: "/Applications/Safari.app")
        #expect(launcher.apps.contains { $0.path == "/Applications/Safari.app" })
        #expect(AppLauncherStore(defaults: defaults).apps.contains { $0.path == "/Applications/Safari.app" })
        launcher.removeApp(path: "/Applications/Safari.app")
        #expect(!launcher.apps.contains { $0.path == "/Applications/Safari.app" })
        launcher.addShortcut(name: "Morning Focus")
        #expect(launcher.shortcuts.first?.runURL?.scheme == "shortcuts")

        let reminders = QuickRemindersStore(defaults: defaults, time: clock)
        reminders.add("Ship Wave 3")
        #expect(reminders.items.count == 1 && !reminders.items[0].isCompleted)
        reminders.toggle(reminders.items[0].id)
        #expect(reminders.items[0].isCompleted)

        let stocks = StocksWatchlistStore(defaults: defaults)
        stocks.addSymbol("tsla")
        #expect(stocks.symbols.contains("TSLA"))

        let focus = FocusHistoryStore(defaults: defaults)
        focus.recordCompletedMinutes(25, on: clock.now)
        #expect(focus.streakDays(at: clock.now) == 1)
        #expect(focus.last7Days(at: clock.now).count == 7)

        let ai = AIUsageStore(defaults: defaults, time: clock)
        ai.update(provider: "Claude Code", tokensUsed: 42000, costUSD: 0.65, windowLimitPercent: 34)
        #expect(ai.providers.first(where: { $0.provider == "Claude Code" })?.tokensUsed == 42000)
    }
}
