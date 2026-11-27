import IslandCore
import IslandDesign
import SwiftUI

struct TimerExpandedCard: View {
    let snapshot: TimerSnapshot
    @Environment(\.timerActions) private var actions
    @Environment(\.quickTools) private var quickTools
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.islandMorphNamespace) private var morphNamespace

    init(snapshot: TimerSnapshot) { self.snapshot = snapshot }

    var body: some View {
        let mascot = quickTools.timerMascot()
        let animates = !reduceMotion && snapshot.endsAt != nil
        let streak = quickTools.focusStreakDays()
        let focusDays = quickTools.focusLast7Days()

        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Label {
                    if let label = snapshot.label {
                        Text(label)
                    } else {
                        Text(snapshot.phase.titleKey, bundle: .module)
                    }
                } icon: {
                    timerIcon(mascot: mascot, animates: animates)
                }
                .font(TypeToken.title.font)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)

                TimerCountdownText(snapshot: snapshot)
                    .font(TypeToken.numeralLarge.font)
                    .monospacedDigit()
                    .foregroundStyle(Palette.textPrimary)

                HStack(spacing: 10) {
                    if let cycle = snapshot.cycle, let total = snapshot.totalCycles {
                        Text("timer.cycle \(cycle) \(total)", bundle: .module)
                            .font(TypeToken.caption.font)
                            .foregroundStyle(Palette.textSecondary)
                    }
                    if streak > 0 || focusDays.contains(where: { $0.minutes > 0 }) {
                        let maxMins = max(focusDays.map(\.minutes).max() ?? 1, 25)
                        HStack(alignment: .bottom, spacing: 3) {
                            ForEach(focusDays, id: \.dayKey) { day in
                                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                                    .fill(day.minutes > 0 ? Palette.signalOrange : Palette.inkPressed)
                                    .frame(width: 5, height: max(3, CGFloat(day.minutes) / CGFloat(maxMins) * 14))
                            }
                        }
                        .frame(height: 14, alignment: .bottom)
                        .accessibilityLabel(Text("tools.focus.streak \(streak)", bundle: .module))
                    }
                }
            }
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                if snapshot.endsAt == nil {
                    control("play.fill", "timer.resume", actions.resume)
                } else {
                    control("pause.fill", "timer.pause", actions.pause).accessibilityLabel(
                        Text(AccessibilityLabels.pauseTimer))
                }
                if snapshot.phase != .simple && snapshot.phase != .stopwatch {
                    control("forward.end.fill", "timer.skip", actions.skip)
                }
                control("xmark", "timer.cancel", actions.cancel)
            }
        }
        .padding(14)
        .islandCard()
    }

    @ViewBuilder
    private func timerIcon(mascot: TimerMascot, animates: Bool) -> some View {
        if let morphNamespace {
            mascotSymbol(mascot: mascot, animates: animates)
                .matchedGeometryEffect(id: "hero-timer-icon", in: morphNamespace)
        } else {
            mascotSymbol(mascot: mascot, animates: animates)
        }
    }

    @ViewBuilder
    private func mascotSymbol(mascot: TimerMascot, animates: Bool) -> some View {
        let base = Image(systemName: mascot.symbolName ?? snapshot.phase.symbol)
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

    private func control(_ symbol: String, _ key: LocalizedStringKey, _ action: @escaping @MainActor () -> Void)
        -> some View
    {
        Button(action: action) {
            Image(systemName: symbol)
                .font(TypeToken.title.font)
                .frame(width: 36, height: 36)
                .background(Palette.inkPressed, in: Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Palette.textPrimary)
        .accessibilityLabel(Text(key, bundle: .module))
    }
}
