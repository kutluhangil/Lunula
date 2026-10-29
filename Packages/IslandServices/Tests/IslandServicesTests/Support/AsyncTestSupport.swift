import Foundation

/// Lets queued main-actor work run and async calls that hop to the global executor (fakes, permission checks)
/// finish and hop back. Spins for a fixed window, longer on CI runners, which are much slower than a laptop.
func settle(_ iterations: Int = 10) async {
    let window: Duration = ProcessInfo.processInfo.environment["CI"] == nil ? .milliseconds(200) : .seconds(1)
    let deadline = ContinuousClock.now + window
    while ContinuousClock.now < deadline {
        for _ in 0..<iterations { await Task.yield() }
        try? await Task.sleep(for: .milliseconds(5))
    }
}
