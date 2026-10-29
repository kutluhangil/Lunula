import Foundation

@testable import IslandServices

/// Records calls; sleeps `delay` seconds to make timeouts and serialization observable.
final class FakeExecutor: ScriptExecuting, @unchecked Sendable {
    private let lock = NSLock()
    private let result: ScriptOutcome
    private let delay: TimeInterval
    private var _callCount = 0
    private var _ranOnMainThread = false
    private var _active = 0
    private var _maxConcurrency = 0
    private var _lastSource: String?

    init(result: ScriptOutcome, delay: TimeInterval = 0) {
        self.result = result
        self.delay = delay
    }

    var callCount: Int { lock.withLock { _callCount } }
    var ranOnMainThread: Bool { lock.withLock { _ranOnMainThread } }
    var maxConcurrency: Int { lock.withLock { _maxConcurrency } }
    var lastSource: String? { lock.withLock { _lastSource } }

    func execute(_ source: String) -> ScriptOutcome {
        lock.withLock {
            _callCount += 1
            _lastSource = source
            _ranOnMainThread = _ranOnMainThread || Thread.isMainThread
            _active += 1
            _maxConcurrency = max(_maxConcurrency, _active)
        }
        if delay > 0 { Thread.sleep(forTimeInterval: delay) }
        lock.withLock { _active -= 1 }
        return result
    }
}
