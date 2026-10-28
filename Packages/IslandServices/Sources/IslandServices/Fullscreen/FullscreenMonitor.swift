import AppKit
import IslandCore

@MainActor
public final class FullscreenMonitor {
    private let workspaceCenter: NotificationCenter
    private let reader: WindowListReading
    private let screens: @MainActor () -> [ScreenDescriptor]
    private let frontmostPID: @MainActor () -> Int32?
    private let settleDelay: Duration

    public init(
        workspaceCenter: NotificationCenter = NSWorkspace.shared.notificationCenter,
        reader: WindowListReading = CGWindowListReader(),
        screens: @escaping @MainActor () -> [ScreenDescriptor],
        frontmostPID: @escaping @MainActor () -> Int32?,
        settleDelay: Duration = .milliseconds(300)
    ) {
        self.workspaceCenter = workspaceCenter
        self.reader = reader
        self.screens = screens
        self.frontmostPID = frontmostPID
        self.settleDelay = settleDelay
    }

    /// Emits per-screen fullscreen state after each space or frontmost-app change, once the transition settles.
    public func updates() -> AsyncStream<[UInt32: Bool]> {
        let (stream, continuation) = AsyncStream<[UInt32: Bool]>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let names = [NSWorkspace.activeSpaceDidChangeNotification, NSWorkspace.didActivateApplicationNotification]
        let pending = PendingTask()
        let tokens = names.map { name in
            workspaceCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    pending.task?.cancel()
                    pending.task = Task { @MainActor [weak self] in
                        guard let self else { return }
                        try? await Task.sleep(for: self.settleDelay)
                        if Task.isCancelled { return }
                        continuation.yield(self.evaluate())
                    }
                }
            }
        }
        let box = TokenBox(tokens)
        continuation.onTermination = { [workspaceCenter] _ in
            for token in box.tokens { workspaceCenter.removeObserver(token) }
            Task { @MainActor in pending.task?.cancel() }
        }
        return stream
    }

    /// A nil frontmost PID means every screen reports false. Quartz y is relative to the primary screen (frame origin zero), not the focused one.
    private func evaluate() -> [UInt32: Bool] {
        let all = screens()
        guard let pid = frontmostPID() else { return Dictionary(uniqueKeysWithValues: all.map { ($0.id, false) }) }
        let windows = reader.windows()
        let primaryHeight = (all.first(where: { $0.frame.origin == .zero }) ?? all.first)?.frame.height ?? 0
        return Dictionary(
            uniqueKeysWithValues: all.map {
                (
                    $0.id,
                    FullscreenHeuristic.isFullscreen(
                        windows: windows, frontmostPID: pid, screen: $0, primaryScreenHeight: primaryHeight)
                )
            })
    }
}

@MainActor private final class PendingTask { var task: Task<Void, Never>? }

private final class TokenBox: @unchecked Sendable {  // immutable after init
    let tokens: [NSObjectProtocol]
    init(_ tokens: [NSObjectProtocol]) { self.tokens = tokens }
}
