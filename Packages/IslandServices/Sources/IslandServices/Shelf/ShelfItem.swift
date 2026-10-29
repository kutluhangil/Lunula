import Foundation

public enum ShelfStorage: Codable, Equatable, Sendable {
    case reference(bookmark: Data)
    case copy(relativePath: String)
}

public struct ShelfItem: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var displayName: String
    public var addedAt: Date
    public var storage: ShelfStorage
    public var byteCount: Int64?
    /// Where the file came from; used to spot duplicates in copy mode.
    public var sourcePath: String?

    public init(
        id: UUID, displayName: String, addedAt: Date, storage: ShelfStorage, byteCount: Int64?, sourcePath: String?
    ) {
        self.id = id
        self.displayName = displayName
        self.addedAt = addedAt
        self.storage = storage
        self.byteCount = byteCount
        self.sourcePath = sourcePath
    }
}

public enum ShelfItemStatus: Equatable, Sendable {
    case available(URL)
    case missing
}

public enum ShelfLimits {
    public static let maxItems = 64
}
