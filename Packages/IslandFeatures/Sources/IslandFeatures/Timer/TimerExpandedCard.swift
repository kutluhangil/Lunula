import IslandCore
import IslandDesign
import SwiftUI

struct TimerExpandedCard: View {
    let snapshot: TimerSnapshot
    @Environment(\.timerActions) private var actions

    init(snapshot: TimerSnapshot) { self.snapshot = snapshot }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Label {
                    if let label = snapshot.label {
                        Text(label)
                    } else {
                        Text(snapshot.phase.titleKey, bundle: .module)
                    }
                } icon: {
                    Image(systemName: snapshot.phase.symbol).foregroundStyle(Palette.signalOrange)
                }
                .font(TypeToken.title.font)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)

                TimerCountdownText(snapshot: snapshot)
                    .font(TypeToken.numeralLarge.font)
                    .monospacedDigit()
                    .foregroundStyle(Palette.textPrimary)

                if let cycle = snapshot.cycle, let total = snapshot.totalCycles {
                    Text("timer.cycle \(cycle) \(total)", bundle: .module)
                        .font(TypeToken.caption.font)
                        .foregroundStyle(Palette.textSecondary)
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
                if snapshot.phase != .simple { control("forward.end.fill", "timer.skip", actions.skip) }
                control("xmark", "timer.cancel", actions.cancel)
            }
        }
        .padding(14)
        .islandCard()
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
