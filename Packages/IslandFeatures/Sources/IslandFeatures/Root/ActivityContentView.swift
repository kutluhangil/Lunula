import IslandCore
import IslandDesign
import SwiftUI

/// The single switch that picks a feature view per content kind. Feature tasks replace their branch
/// (Integrator note); until then every branch draws the generic fallback (symbol + title).
struct ActivityContentView: View {
    enum Slot { case compactLeading, compactTrailing, expanded }

    let activity: Activity
    let slot: Slot

    init(activity: Activity, slot: Slot) {
        self.activity = activity
        self.slot = slot
    }

    var body: some View {
        switch activity.content {
        case .nowPlaying(let track):
            switch slot {
            case .compactLeading: NowPlayingCompactLeading(snapshot: track)
            case .compactTrailing: NowPlayingCompactTrailing(snapshot: track, accent: activity.accent)
            case .expanded: NowPlayingExpandedCard(snapshot: track, accent: activity.accent)
            }
        case .timer(let timer):
            switch slot {
            case .compactLeading: TimerCompactLeading(snapshot: timer)
            case .compactTrailing: TimerCompactTrailing(snapshot: timer)
            case .expanded: TimerExpandedCard(snapshot: timer)
            }
        case .calendar(let event):
            switch slot {
            case .compactLeading: CalendarCompactLeading(event: event)
            case .compactTrailing: CalendarCompactTrailing(event: event)
            case .expanded: CalendarExpandedCard(event: event)
            }
        case .custom(let custom): fallback(symbol: custom.symbol ?? "circle.fill", title: custom.title)
        }
    }

    @ViewBuilder private func fallback(symbol: String, title: String) -> some View {
        switch slot {
        case .compactLeading:
            Image(systemName: symbol).font(TypeToken.body.font).foregroundStyle(Palette.textPrimary)
        case .compactTrailing:
            EmptyView()
        case .expanded:
            HStack(spacing: 8) {
                Image(systemName: symbol).font(TypeToken.title.font)
                Text(title).font(TypeToken.title.font).lineLimit(1)
            }
            .foregroundStyle(Palette.textPrimary)
        }
    }
}
