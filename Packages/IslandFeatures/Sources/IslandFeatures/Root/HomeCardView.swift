import IslandCore
import IslandDesign
import SwiftUI

/// Same pattern as ActivityContentView: one switch, generic fallback until feature tasks bind their cards.
struct HomeCardView: View {
    let card: HomeCard

    init(card: HomeCard) { self.card = card }

    @Environment(\.islandLayout) private var layout
    @Environment(\.nowPlayingActions) private var nowPlaying
    @Environment(\.calendarActions) private var calendar

    var body: some View {
        switch card {
        case .timerQuickStart:
            TimerQuickStartTile()
        case .calendarAccess:
            CalendarAccessTile()
        case .meeting:
            if let activity = layout.primaryCalendarActivity, case .calendar(let event) = activity.content {
                CalendarExpandedCard(event: event)
            } else if let event = calendar.nextEvent() {
                CalendarExpandedCard(event: event)
            } else {
                fallbackCard
            }
        case .nextEvent:
            if let event = calendar.nextEvent() { NextEventTile(event: event) } else { fallbackCard }
        case .permission(let source):
            PermissionCard(source: source) { nowPlaying.requestConsent(source) }
        case .nowPlaying:
            if let activity = layout.activity("nowPlaying"), case .nowPlaying(let track) = activity.content {
                NowPlayingExpandedCard(snapshot: track, accent: activity.accent)
            } else {
                fallbackCard
            }
        case .timer:
            if case .timer(let snapshot)? = layout.activity(TimerSnapshot.activityID)?.content {
                TimerExpandedCard(snapshot: snapshot)
            } else {
                fallbackCard
            }
        default:
            fallbackCard
        }
    }

    private var fallbackCard: some View {
        let (symbol, title) = Self.fallback(card)
        return
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: symbol).font(TypeToken.title.font)
                Text(title, bundle: .module).font(TypeToken.caption.font).foregroundStyle(Palette.textSecondary)
            }
            .foregroundStyle(Palette.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(12)
            .background(Palette.inkRaised, in: RoundedRectangle(cornerRadius: Radii.card, style: .continuous))
    }

    static func fallback(_ card: HomeCard) -> (String, LocalizedStringKey) {
        switch card {
        case .permission: ("lock.open", "home.card.permission")
        case .nowPlaying: ("music.note", "home.card.nowPlaying")
        case .meeting: ("video", "home.card.meeting")
        case .timer: ("timer", "home.card.timer")
        case .weather: ("cloud.sun", "home.card.weather")
        case .nextEvent: ("calendar", "home.card.nextEvent")
        case .timerQuickStart: ("timer", "home.card.timerQuickStart")
        case .calendarAccess: ("calendar.badge.plus", "home.card.calendarAccess")
        }
    }
}

extension EnvironmentValues {
    /// The current island layout, for home cards that show a live activity (timer, music).
    @Entry var islandLayout = IslandLayout.empty
}

extension IslandLayout {
    func activity(_ id: ActivityID) -> Activity? { ([primary].compactMap { $0 } + detached).first { $0.id == id } }

    var primaryCalendarActivity: Activity? {
        ([primary].compactMap { $0 } + detached).first { $0.kind == .calendar }
    }
}

extension TimerSnapshot {
    static let activityID: ActivityID = "timer"
}
