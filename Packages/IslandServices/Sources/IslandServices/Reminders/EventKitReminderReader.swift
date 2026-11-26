import EventKit
import Foundation

/// EventKit reminders adapter. Never prompts unless `requestAccess()` is explicitly called by the user.
public final class EventKitReminderReader: ReminderReading, @unchecked Sendable {
    private let store = EKEventStore()

    public init() {}

    public func authorization() -> CalendarAuthorization {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .notDetermined: .notDetermined
        case .fullAccess: .fullAccess
        case .writeOnly: .writeOnly
        case .restricted: .restricted
        default: .denied
        }
    }

    public func requestAccess() async -> CalendarAuthorization {
        _ = try? await store.requestFullAccessToReminders()
        let status = authorization()
        if status == .fullAccess { store.reset() }
        return status
    }

    public func incompleteReminders() async -> [ReminderRecord] {
        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: nil, ending: nil, calendars: nil)
        return await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                let mapped = (reminders ?? [])
                    .sorted { lhs, rhs in
                        let lDate = lhs.dueDateComponents?.date ?? lhs.creationDate ?? .distantFuture
                        let rDate = rhs.dueDateComponents?.date ?? rhs.creationDate ?? .distantFuture
                        return lDate < rDate
                    }
                    .map { reminder in
                        ReminderRecord(
                            id: reminder.calendarItemIdentifier,
                            title: reminder.title ?? "",
                            isCompleted: reminder.isCompleted,
                            dueDate: reminder.dueDateComponents?.date,
                            listTitle: reminder.calendar?.title)
                    }
                    .filter { !$0.title.isEmpty }
                continuation.resume(returning: mapped)
            }
        }
    }

    public func addReminder(title: String) async -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let defaultCalendar = store.defaultCalendarForNewReminders() else { return false }
        let reminder = EKReminder(eventStore: store)
        reminder.title = trimmed
        reminder.calendar = defaultCalendar
        do {
            try store.save(reminder, commit: true)
            return true
        } catch {
            return false
        }
    }

    public func toggleReminder(id: String) async -> Bool {
        guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else { return false }
        reminder.isCompleted.toggle()
        do {
            try store.save(reminder, commit: true)
            return true
        } catch {
            return false
        }
    }

    public func removeReminder(id: String) async -> Bool {
        guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else { return false }
        do {
            try store.remove(reminder, commit: true)
            return true
        } catch {
            return false
        }
    }
}
