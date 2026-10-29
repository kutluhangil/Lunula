import AppIntents
import IslandCore

struct StartTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.timer.title"
    static let supportedModes: IntentModes = .background

    @Parameter(title: "intent.param.minutes", inclusiveRange: (1, 600)) var minutes: Double

    @Dependency private var timer: TimerController

    @MainActor func perform() async throws -> some IntentResult { try await perform(using: timer) }

    @MainActor func perform(using timer: TimerController) async throws -> some IntentResult {
        guard CustomActivityLimits.timerMinutes.contains(minutes) else {
            throw IntentError.invalid(.invalidParameter("minutes"))
        }
        timer.start(minutes: minutes, label: nil)
        return .result()
    }
}

struct ToggleIslandIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.toggle.title"
    static let supportedModes: IntentModes = .background

    @Dependency private var toggler: IslandToggler

    @MainActor func perform() async throws -> some IntentResult {
        toggler.toggle()
        return .result()
    }
}
