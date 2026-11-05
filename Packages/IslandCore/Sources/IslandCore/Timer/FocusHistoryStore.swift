import Foundation
import Observation

public struct FocusDayEntry: Codable, Equatable, Sendable {
    public var dayKey: String
    public var minutes: Int

    public init(dayKey: String, minutes: Int) {
        self.dayKey = dayKey
        self.minutes = minutes
    }
}

/// Tracks completed focus minutes per calendar day for 7-day charts and daily streaks.
@MainActor @Observable public final class FocusHistoryStore {
    static let storageKey = "focus.history.v1"

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let calendar: Calendar
    public private(set) var entries: [FocusDayEntry] = []

    public init(defaults: UserDefaults, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
        if let data = defaults.data(forKey: Self.storageKey),
            let decoded = try? JSONDecoder().decode([FocusDayEntry].self, from: data)
        {
            entries = decoded
        }
    }

    public func recordCompletedMinutes(_ minutes: Int, on date: Date) {
        guard minutes > 0 else { return }
        let key = Self.dayKey(for: date, calendar: calendar)
        if let idx = entries.firstIndex(where: { $0.dayKey == key }) {
            entries[idx].minutes += minutes
        } else {
            entries.append(FocusDayEntry(dayKey: key, minutes: minutes))
        }
        if entries.count > 60 {
            entries = Array(entries.suffix(60))
        }
        persist()
    }

    public func streakDays(at now: Date) -> Int {
        var count = 0
        var cursor = now
        while true {
            let key = Self.dayKey(for: cursor, calendar: calendar)
            if let entry = entries.first(where: { $0.dayKey == key }), entry.minutes > 0 {
                count += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
                cursor = prev
            } else {
                break
            }
        }
        return count
    }

    public func last7Days(at now: Date) -> [FocusDayEntry] {
        (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: now) ?? now
            let key = Self.dayKey(for: date, calendar: calendar)
            let mins = entries.first(where: { $0.dayKey == key })?.minutes ?? 0
            return FocusDayEntry(dayKey: key, minutes: mins)
        }
    }

    public static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
