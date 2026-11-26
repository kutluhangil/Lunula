import Foundation

public struct ReminderRecord: Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var isCompleted: Bool
    public var dueDate: Date?
    public var listTitle: String?

    public init(id: String, title: String, isCompleted: Bool, dueDate: Date? = nil, listTitle: String? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.listTitle = listTitle
    }
}
