import Foundation

public protocol ReminderReading: Sendable {
    func authorization() -> CalendarAuthorization
    func requestAccess() async -> CalendarAuthorization
    func incompleteReminders() async -> [ReminderRecord]
    func addReminder(title: String) async -> Bool
    func toggleReminder(id: String) async -> Bool
    func removeReminder(id: String) async -> Bool
}
