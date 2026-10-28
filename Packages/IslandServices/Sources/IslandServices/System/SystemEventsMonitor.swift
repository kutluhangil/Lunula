import AppKit

public enum SystemEvent: Sendable {
    case willSleep, didWake, screensDidSleep, screensDidWake
}

@MainActor
public final class SystemEventsMonitor {
    private let workspaceCenter: NotificationCenter

    public init(workspaceCenter: NotificationCenter = NSWorkspace.shared.notificationCenter) {
        self.workspaceCenter = workspaceCenter
    }

    public func events() -> AsyncStream<SystemEvent> {
        let (stream, continuation) = AsyncStream<SystemEvent>.makeStream()
        let map: [(Notification.Name, SystemEvent)] = [
            (NSWorkspace.willSleepNotification, .willSleep),
            (NSWorkspace.didWakeNotification, .didWake),
            (NSWorkspace.screensDidSleepNotification, .screensDidSleep),
            (NSWorkspace.screensDidWakeNotification, .screensDidWake),
        ]
        let tokens = map.map { name, event in
            workspaceCenter.addObserver(forName: name, object: nil, queue: nil) { _ in continuation.yield(event) }
        }
        let box = SystemTokenBox(tokens)
        continuation.onTermination = { [workspaceCenter] _ in
            for token in box.tokens { workspaceCenter.removeObserver(token) }
        }
        return stream
    }
}

private final class SystemTokenBox: @unchecked Sendable {  // immutable after init
    let tokens: [NSObjectProtocol]
    init(_ tokens: [NSObjectProtocol]) { self.tokens = tokens }
}
