import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleIsland = Self("toggleIsland", default: .init(.space, modifiers: [.control, .option]))
}

@MainActor enum GlobalShortcut {
    static func install(onToggle: @escaping @MainActor () -> Void) {
        KeyboardShortcuts.onKeyUp(for: .toggleIsland) { onToggle() }
    }
}
