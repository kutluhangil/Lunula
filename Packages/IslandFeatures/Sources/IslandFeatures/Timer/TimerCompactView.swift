import IslandCore
import IslandDesign
import SwiftUI

extension TimerPhase {
    var symbol: String {
        switch self {
        case .simple: "timer"
        case .focus: "brain.head.profile"
        case .shortBreak, .longBreak: "cup.and.saucer"
        case .stopwatch: "stopwatch"
        }
    }

    var titleKey: LocalizedStringKey {
        switch self {
        case .simple: "timer.title"
        case .focus: "timer.phase.focus"
        case .shortBreak: "timer.phase.shortBreak"
        case .longBreak: "timer.phase.longBreak"
        case .stopwatch: "timer.stopwatch"
        }
    }
}

struct TimerCompactLeading: View {
    let snapshot: TimerSnapshot
    @Environment(\.quickTools) private var quickTools
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.islandMorphNamespace) private var morphNamespace

    var body: some View {
        let mascot = quickTools.timerMascot()
        let animates = !reduceMotion && snapshot.endsAt != nil
        if let morphNamespace {
            mascotSymbol(mascot: mascot, animates: animates)
                .frame(width: 16, height: 16)
                .matchedGeometryEffect(id: "hero-timer-icon", in: morphNamespace)
        } else {
            mascotSymbol(mascot: mascot, animates: animates)
                .frame(width: 16, height: 16)
        }
    }

    @ViewBuilder
    private func mascotSymbol(mascot: TimerMascot, animates: Bool) -> some View {
        let base = Image(systemName: mascot.symbolName ?? snapshot.phase.symbol)
            .font(TypeToken.body.font)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(Palette.signalOrange)
        switch mascot {
        case .none:
            base
        case .flame:
            base.symbolEffect(.variableColor.iterative, options: .repeating, isActive: animates)
        case .hare:
            if reduceMotion {
                base
            } else {
                base
                    .symbolEffect(.bounce, value: snapshot.phase)
                    .symbolEffect(.pulse, options: .repeating, isActive: animates)
            }
        case .tortoise, .cat, .bird:
            base.symbolEffect(.breathe, options: .repeating, isActive: animates)
        }
    }
}

/// Countdown rendered by the system clock (`Text(timerInterval:)`), so the app is not woken every second.
struct TimerCompactTrailing: View {
    let snapshot: TimerSnapshot

    init(snapshot: TimerSnapshot) { self.snapshot = snapshot }

    var body: some View {
        TimerCountdownText(snapshot: snapshot)
            .font(TypeToken.numeralCompact.font)
            .monospacedDigit()
            .foregroundStyle(snapshot.endsAt == nil ? Palette.textSecondary : Palette.textPrimary)
    }
}

struct TimerCountdownText: View {
    let snapshot: TimerSnapshot

    var body: some View {
        if snapshot.phase == .stopwatch, let startedAt = snapshot.startedAt, snapshot.endsAt != nil {
            Text(timerInterval: min(startedAt, .now)...Date.distantFuture, countsDown: false)
        } else if let endsAt = snapshot.endsAt, snapshot.phase != .stopwatch {
            Text(timerInterval: Date.now...max(endsAt, .now), countsDown: true)
        } else {
            Text(Duration.seconds((snapshot.pausedRemaining ?? 0).rounded(.up)), format: .time(pattern: .minuteSecond))
        }
    }
}
