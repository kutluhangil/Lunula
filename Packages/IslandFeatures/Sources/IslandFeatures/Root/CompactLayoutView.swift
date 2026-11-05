import IslandCore
import IslandDesign
import SwiftUI

/// Closed island with an activity: content in the wings left and right of the hardware notch, or a single pill row on
/// notchless displays (L2).
struct CompactLayoutView: View {
    let activity: Activity
    let notchWidth: CGFloat
    var hasHardwareNotch = true

    var body: some View {
        if hasHardwareNotch {
            HStack(spacing: 0) {
                ActivityContentView(activity: activity, slot: .compactLeading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Color.clear.frame(width: notchWidth)
                ActivityContentView(activity: activity, slot: .compactTrailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, Radii.closedShoulder + Spacing.compactPadding)
            .frame(maxHeight: .infinity)
        } else {
            PillCompactView(activity: activity)
        }
    }
}

/// L2 — Active Pill Mode (180 × 22 pt) on notchless displays: 12 pt symbol + 11 pt title + 11 pt status.
private struct PillCompactView: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 6) {
            leadingSymbol
                .font(.system(size: 11, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .frame(width: 12, height: 12)
            Text(title)
                .font(TypeToken.caption.font)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            trailingStatus
                .font(TypeToken.caption.font.monospacedDigit())
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder private var leadingSymbol: some View {
        switch activity.content {
        case .nowPlaying:
            Image(systemName: "waveform")
                .foregroundStyle(activity.accent.map(Palette.color) ?? Palette.textPrimary)
        case .timer(let timer):
            Image(systemName: timer.phase.symbol)
                .foregroundStyle(Palette.signalOrange)
        case .calendar:
            Image(systemName: "video.fill")
                .foregroundStyle(Palette.signalOrange)
        case .custom(let custom):
            Image(systemName: CustomSymbol.resolve(custom.symbol))
                .foregroundStyle(activity.accent.map(Palette.color) ?? Palette.textPrimary)
        }
    }

    private var title: String {
        switch activity.content {
        case .nowPlaying(let track): track.title
        case .timer(let timer): timer.label ?? ""
        case .calendar(let event): event.title
        case .custom(let custom): custom.title
        }
    }

    @ViewBuilder private var trailingStatus: some View {
        switch activity.content {
        case .nowPlaying(let track):
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(IslandFormat.trackTime(track.position(at: context.date)))
            }
        case .timer(let timer):
            TimerCountdownText(snapshot: timer)
        case .calendar(let event):
            CalendarCompactTrailing(event: event)
        case .custom(let custom):
            CustomCompactTrailing(snapshot: custom, accent: activity.accent)
        }
    }
}
