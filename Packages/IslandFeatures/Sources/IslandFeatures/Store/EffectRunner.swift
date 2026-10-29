import IslandCore

/// Executes reducer effects. One pending token per timer kind: scheduling a kind again replaces the old one.
@MainActor final class EffectRunner {
    private let time: IslandTime
    private let panel: PanelControlling
    private let feedback: FeedbackPlaying
    private let speed: @MainActor () -> Double
    private var pending: [IslandTimer: ScheduledToken] = [:]

    init(
        time: IslandTime, panel: PanelControlling, feedback: FeedbackPlaying, speed: @escaping @MainActor () -> Double
    ) {
        self.time = time
        self.panel = panel
        self.feedback = feedback
        self.speed = speed
    }

    func run(_ effects: [IslandEffect], dispatch: @escaping @MainActor (IslandEvent) -> Void) {
        for effect in effects {
            switch effect {
            case .schedule(let kind, let delay):
                pending[kind]?.cancel()
                pending[kind] = time.schedule(after: delay) { [weak self] in
                    guard let self else { return }
                    pending[kind] = nil
                    dispatch(event(firing: kind))
                }
            case .cancel(let kind):
                pending.removeValue(forKey: kind)?.cancel()
            case .playHaptic(let kind):
                feedback.play(kind)
            case .playSound(let kind):
                feedback.play(kind)
            case .makePanelKey(let key):
                panel.makeKey(key)
            case .setMouseEventsIgnored(let ignored):
                panel.setMouseEventsIgnored(ignored)
            }
        }
    }

    private func event(firing kind: IslandTimer) -> IslandEvent {
        switch kind {
        case .dwell: .pointerDwellElapsed(speed: speed())
        case .exitGrace: .exitGraceElapsed
        case .alertExpiry: .alertExpired
        }
    }
}
