import Foundation

enum CalendarLabelState: Equatable { case countdown, now, started }

enum CalendarLabel {
    static func state(start: Date, now: Date) -> CalendarLabelState {
        let d = start.timeIntervalSince(now)
        if d > 60 { return .countdown }
        return d >= -60 ? .now : .started
    }
}
