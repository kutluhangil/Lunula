import Foundation
import Observation

/// Single countdown or Pomodoro, persisted on every change so it survives relaunch and sleep (wall-clock based).
@MainActor @Observable public final class TimerController: ActivityProviding, AlertProviding {
    public static let activityID: ActivityID = "timer"
    static let defaultsKey = "timer.v1"
    /// A timer that finished while Lunula was quit is announced only if it ended this recently.
    static let missedAlertWindow: TimeInterval = 600

    private struct Persisted: Codable {
        var timer: CountdownTimer?
        var pomodoro: PomodoroProgress?
    }

    @ObservationIgnored private let time: IslandTime
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let plan: PomodoroPlan
    @ObservationIgnored private var finishToken: ScheduledToken?
    @ObservationIgnored public var onActivitiesChange: (@MainActor () -> Void)?
    @ObservationIgnored public var onAlert: (@MainActor (TransientAlert) -> Void)?

    public private(set) var current: CountdownTimer?
    public private(set) var pomodoro: PomodoroProgress?

    /// Reads persisted state only; `restore()` (after `onAlert` is bound) resumes scheduling and late alerts.
    public init(time: IslandTime, defaults: UserDefaults, plan: PomodoroPlan = .standard) {
        self.time = time
        self.defaults = defaults
        self.plan = plan
        if let data = defaults.data(forKey: Self.defaultsKey),
            let saved = try? JSONDecoder().decode(Persisted.self, from: data)
        {
            current = saved.timer
            pomodoro = saved.pomodoro
        }
    }

    public var activities: [Activity] {
        guard let current else { return [] }
        let now = time.now
        let content = ActivityContent.timer(
            current.snapshot(
                at: now, cycle: pomodoro.map { $0.completedFocusSessions + 1 },
                totalCycles: pomodoro == nil ? nil : plan.focusSessionsBeforeLongBreak))
        return [
            Activity(
                id: Self.activityID, priority: ActivityPriorityRules.priority(for: content, now: now),
                startedAt: current.startedAt, updatedAt: now, expiresAt: nil, content: content, accent: nil)
        ]
    }

    public func start(minutes: Double, label: String?) {
        pomodoro = nil
        begin(
            CountdownTimer(
                id: Self.activityID, label: label, phase: .simple, duration: minutes * 60, startedAt: time.now))
    }

    public func startPomodoro() {
        let progress = PomodoroProgress()
        pomodoro = progress
        begin(phaseTimer(progress, label: nil))
    }

    public func pause() {
        guard var timer = current else { return }
        timer.pause(at: time.now)
        finishToken?.cancel()
        update(timer)
    }

    public func resume() {
        guard var timer = current else { return }
        timer.resume(at: time.now)
        update(timer)
        scheduleFinish()
    }

    public func cancel() {
        finishToken?.cancel()
        current = nil
        pomodoro = nil
        defaults.removeObject(forKey: Self.defaultsKey)
        onActivitiesChange?()
    }

    /// Pomodoro: jump to the next phase. Simple timer: stop.
    public func skip() {
        guard pomodoro != nil else { return cancel() }
        advancePomodoro(label: current?.label)
    }

    public func restore() {
        guard let timer = current else { return }
        let now = time.now
        guard timer.isFinished(at: now) else {
            scheduleFinish()
            return
        }
        if let end = timer.endDate(), now.timeIntervalSince(end) <= Self.missedAlertWindow {
            onAlert?(Self.finishedAlert(timer))
        }
        cancel()
    }

    // MARK: - Private

    private func begin(_ timer: CountdownTimer) {
        update(timer)
        scheduleFinish()
    }

    private func update(_ timer: CountdownTimer) {
        current = timer
        persist()
        onActivitiesChange?()
    }

    private func scheduleFinish() {
        finishToken?.cancel()
        guard let end = current?.endDate() else { return }
        // Continuous clock: a deadline passed during sleep fires right after wake.
        finishToken = time.schedule(after: max(0, end.timeIntervalSince(time.now))) { [weak self] in self?.finish() }
    }

    private func finish() {
        guard let timer = current else { return }
        guard timer.isFinished(at: time.now) else {
            scheduleFinish()
            return
        }
        onAlert?(Self.finishedAlert(timer))
        if pomodoro != nil {
            advancePomodoro(label: timer.label)
        } else {
            cancel()
        }
    }

    private func advancePomodoro(label: String?) {
        guard var progress = pomodoro else { return }
        progress.advance(plan: plan)
        pomodoro = progress
        begin(phaseTimer(progress, label: label))
    }

    private func phaseTimer(_ progress: PomodoroProgress, label: String?) -> CountdownTimer {
        CountdownTimer(
            id: Self.activityID, label: label, phase: progress.phase, duration: progress.duration(plan: plan),
            startedAt: time.now)
    }

    private func persist() {
        do {
            defaults.set(
                try JSONEncoder().encode(Persisted(timer: current, pomodoro: pomodoro)), forKey: Self.defaultsKey)
        } catch {
            assertionFailure("Timer state could not be encoded: \(error)")
        }
    }

    static func finishedAlert(_ timer: CountdownTimer) -> TransientAlert {
        TransientAlert(
            id: UUID(), kind: .timerFinished, detail: .timer(label: timer.label, phase: timer.phase), tint: .orange,
            duration: 6, priority: .critical)
    }
}
