import AppKit
import IslandCore

@MainActor public final class SystemFeedbackPlayer: FeedbackPlaying {
    private let performer: NSHapticFeedbackPerformer
    private let playSound: @MainActor (String) -> Void
    private let preferences: @MainActor () -> (haptics: Bool, sounds: Bool)

    public init(
        performer: NSHapticFeedbackPerformer = NSHapticFeedbackManager.defaultPerformer,
        playSound: @escaping @MainActor (String) -> Void = { NSSound(named: $0)?.play() },
        preferences: @escaping @MainActor () -> (haptics: Bool, sounds: Bool)
    ) {
        self.performer = performer
        self.playSound = playSound
        self.preferences = preferences
    }

    public func play(_ haptic: HapticKind) {
        guard preferences().haptics else { return }
        let pattern: NSHapticFeedbackManager.FeedbackPattern =
            switch haptic {
            case .alignment: .alignment
            case .levelChange: .levelChange
            case .generic: .generic
            }
        performer.perform(pattern, performanceTime: .now)
    }

    public func play(_ sound: SoundKind) {
        guard preferences().sounds else { return }
        switch sound {
        case .timerFinished: playSound("Glass")
        }
    }
}
