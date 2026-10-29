import IslandCore
import Observation

/// One store per screen: the pointer is screen-specific; activity layout and alerts are broadcast to every store.
@MainActor @Observable public final class IslandStore {
    public private(set) var state = IslandState()
    @ObservationIgnored private let runner: EffectRunner

    public init(
        time: IslandTime, panel: PanelControlling, feedback: FeedbackPlaying, speed: @escaping @MainActor () -> Double
    ) {
        runner = EffectRunner(time: time, panel: panel, feedback: feedback, speed: speed)
    }

    public func send(_ event: IslandEvent) {
        let transition = IslandReducer.reduce(state, event)
        state = transition.state
        runner.run(transition.effects) { [weak self] in self?.send($0) }
    }
}
