import Foundation

public protocol EventReading: Sendable {
    func authorization() -> CalendarAuthorization
    func requestAccess() async -> CalendarAuthorization
    func events(from: Date, to: Date) async -> [CalendarEventRecord]
}
