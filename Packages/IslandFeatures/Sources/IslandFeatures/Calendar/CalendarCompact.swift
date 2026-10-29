import IslandCore
import IslandDesign
import SwiftUI

struct CalendarCompactLeading: View {
    let event: EventSnapshot

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(event.calendarColor.map(Palette.color) ?? Palette.textSecondary).frame(width: 6, height: 6)
            if event.meetingLink != nil {
                Image(systemName: "video.fill").font(TypeToken.caption.font).foregroundStyle(Palette.textPrimary)
            }
        }
    }
}

/// Countdown by the system clock until a minute before start, then "Now", then "Started".
struct CalendarCompactTrailing: View {
    let event: EventSnapshot

    var body: some View {
        TimelineView(.explicit([event.start.addingTimeInterval(-60), event.start.addingTimeInterval(60)])) { context in
            switch CalendarLabel.state(start: event.start, now: context.date) {
            case .countdown:
                Text(timerInterval: Date.now...max(event.start, .now), countsDown: true)
                    .font(TypeToken.numeralCompact.font).monospacedDigit()
            case .now: Text("calendar.now", bundle: .module).font(TypeToken.caption.font)
            case .started: Text("calendar.started", bundle: .module).font(TypeToken.caption.font)
            }
        }
        .foregroundStyle(Palette.textPrimary)
    }
}
