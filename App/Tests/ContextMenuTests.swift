import AppKit
import KeyboardShortcuts
import Testing

@testable import Lunula

@MainActor @Suite struct ContextMenuTests {
    let noop = ContextMenuActions(openSettings: {}, toggleMute: {}, quit: {})

    @Test func menuHasSettingsMuteSeparatorQuit() {
        let m = ContextMenuBuilder.menu(isMuted: false, actions: noop)
        #expect(
            m.items.count == 4 && m.items[2].isSeparatorItem && m.items[0].keyEquivalent == ","
                && m.items[3].keyEquivalent == "q")
    }

    @Test func muteItemTitleReflectsState() {
        #expect(
            ContextMenuBuilder.menu(isMuted: false, actions: noop).items[1].title
                != ContextMenuBuilder.menu(isMuted: true, actions: noop).items[1].title)
    }

    @Test func shortcutDefaultIsControlOptionSpace() {
        #expect(KeyboardShortcuts.Name.toggleIsland.defaultShortcut == .init(.space, modifiers: [.control, .option]))
    }
}
