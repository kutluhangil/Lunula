import IslandCore
import IslandDesign
import SwiftUI

/// Same pattern as ActivityContentView: one switch, generic fallback until feature tasks bind their cards.
struct HomeCardView: View {
    let card: HomeCard

    init(card: HomeCard) { self.card = card }

    var body: some View {
        let (symbol, title) = Self.fallback(card)
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
