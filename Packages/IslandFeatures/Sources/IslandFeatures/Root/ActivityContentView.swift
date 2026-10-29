import IslandCore
import IslandDesign
import SwiftUI

/// The single switch that picks a feature view per content kind and slot.
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
        case .custom(let custom):
            switch slot {
            case .compactLeading: CustomCompactLeading(snapshot: custom, accent: activity.accent)
            case .compactTrailing: CustomCompactTrailing(snapshot: custom, accent: activity.accent)
            case .expanded: CustomExpandedCard(snapshot: custom, accent: activity.accent)
            }
        }
    }
}
