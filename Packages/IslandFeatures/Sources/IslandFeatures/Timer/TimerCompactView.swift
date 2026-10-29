import IslandCore
import IslandDesign
import SwiftUI

extension TimerPhase {
    var symbol: String {
        switch self {
        case .simple: "timer"
        case .focus: "brain.head.profile"
        case .shortBreak, .longBreak: "cup.and.saucer"
        }
    }

    var titleKey: LocalizedStringKey {
        switch self {
        case .simple: "timer.title"
        case .focus: "timer.phase.focus"
        case .shortBreak: "timer.phase.shortBreak"
        case .longBreak: "timer.phase.longBreak"
        }
    }
}

struct TimerCompactLeading: View {
    let snapshot: TimerSnapshot

    var body: some View {
        Image(systemName: snapshot.phase.symbol).font(TypeToken.body.font).foregroundStyle(Palette.signalOrange)
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
        if let endsAt = snapshot.endsAt {
            Text(timerInterval: Date.now...max(endsAt, .now), countsDown: true)
        } else {
            Text(Duration.seconds((snapshot.pausedRemaining ?? 0).rounded(.up)), format: .time(pattern: .minuteSecond))
        }
    }
}
