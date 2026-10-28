import Foundation

public struct IslandLayout: Equatable, Sendable {
    public var primary: Activity?
    public var detached: [Activity]
    public var overflowCount: Int

    public init(primary: Activity?, detached: [Activity], overflowCount: Int) {
        self.primary = primary
        self.detached = detached
        self.overflowCount = overflowCount
    }

    public static let empty = IslandLayout(primary: nil, detached: [], overflowCount: 0)

    public func contains(_ id: ActivityID) -> Bool {
        primary?.id == id || detached.contains { $0.id == id }
    }
}
