import IslandCore

@MainActor final class FakePanel: PanelControlling {
    private(set) var ignoredHistory: [Bool] = []
    private(set) var keyHistory: [Bool] = []
    func setMouseEventsIgnored(_ ignored: Bool) { ignoredHistory.append(ignored) }
    func makeKey(_ key: Bool) { keyHistory.append(key) }
}

@MainActor final class FakeFeedback: FeedbackPlaying {
    private(set) var haptics: [HapticKind] = []
    private(set) var sounds: [SoundKind] = []
    func play(_ haptic: HapticKind) { haptics.append(haptic) }
    func play(_ sound: SoundKind) { sounds.append(sound) }
}
