import AppKit
import IslandCore

@MainActor
public final class ScreenService {
    public private(set) var current: [ScreenDescriptor]

    private let debounce: Duration
    private let provider: @MainActor () -> [ScreenDescriptor]
    private var observers: [(center: NotificationCenter, token: NSObjectProtocol)] = []
    private var pending: Task<Void, Never>?
    private var isStopped = false
    private var continuations: [UUID: AsyncStream<[ScreenDescriptor]>.Continuation] = [:]

    public init(
        center: NotificationCenter = .default,
        workspaceCenter: NotificationCenter = NSWorkspace.shared.notificationCenter,
        debounce: Duration = .milliseconds(150),
        provider: @escaping @MainActor () -> [ScreenDescriptor] = ScreenService.liveScreens
    ) {
        self.debounce = debounce
        self.provider = provider
        self.current = provider()
        observe(center, NSApplication.didChangeScreenParametersNotification)
        observe(workspaceCenter, NSWorkspace.didWakeNotification)
        observe(workspaceCenter, NSWorkspace.screensDidWakeNotification)
        observe(workspaceCenter, NSWorkspace.sessionDidBecomeActiveNotification)
    }

    isolated deinit { stop() }

    public func updates() -> AsyncStream<[ScreenDescriptor]> {
        let id = UUID()
        let (stream, continuation) = AsyncStream<[ScreenDescriptor]>.makeStream()
        if isStopped {
            continuation.finish()
            return stream
        }
        continuations[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { @MainActor in self?.continuations[id] = nil }
        }
        return stream
    }

    /// Removes every observer, cancels the pending recompute and ends all streams.
    public func stop() {
        isStopped = true
        for (center, token) in observers { center.removeObserver(token) }
        observers = []
        pending?.cancel()
        pending = nil
        for continuation in continuations.values { continuation.finish() }
        continuations = [:]
    }

    public static func liveScreens() -> [ScreenDescriptor] {
        NSScreen.screens.map { ScreenDescriptor($0, isMain: $0 == NSScreen.main) }
    }

    private func observe(_ center: NotificationCenter, _ name: Notification.Name) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.schedule() }
        }
        observers.append((center, token))
    }

    private func schedule() {
        pending?.cancel()
        pending = Task { [weak self, debounce] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled, let self else { return }
            // Published even when equal: positions can be stale after wake.
            current = provider()
            for continuation in continuations.values { continuation.yield(current) }
        }
    }
}
