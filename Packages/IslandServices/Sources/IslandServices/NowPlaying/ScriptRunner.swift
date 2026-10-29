import AppKit

/// Serial, off-main AppleScript execution with a hard timeout. A target that is not running is never scripted:
/// `tell application` would launch it.
public actor ScriptRunner {
    private let executor: ScriptExecuting
    private let isRunning: @Sendable (String) -> Bool
    private let timeout: Duration
    private let queue = DispatchQueue(label: "com.kutluhangul.lunula.scripts", qos: .userInitiated)

    public init(
        executor: ScriptExecuting = AppleScriptExecutor(),
        isRunning: @escaping @Sendable (String) -> Bool = ScriptRunner.isAppRunning,
        timeout: Duration = .seconds(1)
    ) {
        self.executor = executor
        self.isRunning = isRunning
        self.timeout = timeout
    }

    public func run(_ source: String, target bundleID: String) async -> ScriptOutcome {
        guard isRunning(bundleID) else { return .notRunning }
        let once = ResumeOnce()
        let executor = executor
        let timeout = timeout
        return await withCheckedContinuation { continuation in
            once.set(continuation)
            queue.async { once.resume(executor.execute(source)) }
            // A dispatch timer, not Task.sleep: the deadline must hold even when the concurrency pool is busy.
            let c = timeout.components
            let nanoseconds = Int(c.seconds) * 1_000_000_000 + Int(c.attoseconds / 1_000_000_000)
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .nanoseconds(nanoseconds)) {
                once.resume(.timedOut)
            }
        }
    }

    public static func isAppRunning(_ bundleID: String) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
    }
}

/// The script result and the timeout race; whichever arrives first resumes the continuation.
private final class ResumeOnce: @unchecked Sendable {  // guarded by `lock`
    private let lock = NSLock()
    private var continuation: CheckedContinuation<ScriptOutcome, Never>?

    func set(_ c: CheckedContinuation<ScriptOutcome, Never>) { lock.withLock { continuation = c } }

    func resume(_ outcome: ScriptOutcome) {
        let c = lock.withLock {
            defer { continuation = nil }
            return continuation
        }
        c?.resume(returning: outcome)
    }
}
