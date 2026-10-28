import Foundation

public enum ActivityPriority: Int, Codable, Comparable, CaseIterable, Sendable {
    case ambient, normal, high, critical

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct Activity: Identifiable, Equatable, Sendable {
    public var id: ActivityID
    public var priority: ActivityPriority
    public var startedAt: Date
    public var updatedAt: Date
    public var expiresAt: Date?
    public var content: ActivityContent
    public var accent: RGBAColor?

    public init(
        id: ActivityID, priority: ActivityPriority, startedAt: Date, updatedAt: Date, expiresAt: Date?,
        content: ActivityContent, accent: RGBAColor?
    ) {
        self.id = id
        self.priority = priority
        self.startedAt = startedAt
        self.updatedAt = updatedAt
        self.expiresAt = expiresAt
        self.content = content
        self.accent = accent
    }

    public var kind: ActivityKind { content.kind }
}
