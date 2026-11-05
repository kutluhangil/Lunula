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
    }

    @MainActor @Test func quickNotesAddAndRemovePersist() {
        let suiteName = "test.quicknotes.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let clock = ManualTime()
        let store = QuickNotesStore(defaults: defaults, time: clock)
        store.add("  Buy espresso beans  ")
        #expect(store.notes.count == 1 && store.notes.first?.text == "Buy espresso beans")
        let id = store.notes[0].id
        store.remove(id)
        #expect(store.notes.isEmpty)
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
