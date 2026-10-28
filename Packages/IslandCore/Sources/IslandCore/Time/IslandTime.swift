import Foundation

@MainActor
public protocol IslandTime: AnyObject {
    var now: Date { get }
    @discardableResult
    func schedule(after delay: TimeInterval, _ action: @escaping @MainActor () -> Void) -> ScheduledToken
}

@MainActor
public final class ScheduledToken {
    private let onCancel: @MainActor () -> Void
    public private(set) var isCancelled = false

    public init(onCancel: @escaping @MainActor () -> Void) { self.onCancel = onCancel }

    /// Idempotent: `onCancel` runs once.
    public func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        onCancel()
    }
}
