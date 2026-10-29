import Foundation
import IslandCore

public struct CalendarEventRecord: Equatable, Sendable {
    public var id: String
    public var title: String
    public var start: Date
    public var end: Date
    public var isAllDay: Bool
    public var calendarColor: RGBAColor?
    public var location: String?
    public var structuredLocationTitle: String?
    public var url: URL?
    public var notes: String?
    public var isDeclined: Bool
    public var isCanceled: Bool

    public init(
        id: String, title: String, start: Date, end: Date, isAllDay: Bool, calendarColor: RGBAColor?,
        location: String?, structuredLocationTitle: String?, url: URL?, notes: String?, isDeclined: Bool,
        isCanceled: Bool
    ) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
        self.calendarColor = calendarColor
        self.location = location
        self.structuredLocationTitle = structuredLocationTitle
        self.url = url
        self.notes = notes
        self.isDeclined = isDeclined
        self.isCanceled = isCanceled
    }
}

public enum CalendarAuthorization: Equatable, Sendable {
    case notDetermined, fullAccess, denied, restricted, writeOnly
}
