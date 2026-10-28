import Foundation

@MainActor
public final class SystemTime: IslandTime {
    public init() {}

    public var now: Date { Date() }

    @discardableResult
    public func schedule(after delay: TimeInterval, _ action: @escaping @MainActor () -> Void) -> ScheduledToken {
        let task = Task { @MainActor in
            // Tolerance lets the system coalesce wakeups (energy budget).
            try? await Task.sleep(for: .seconds(delay), tolerance: .seconds(max(0.01, delay * 0.1)))
            if !Task.isCancelled { action() }
        }
        return ScheduledToken { task.cancel() }
    }
}
