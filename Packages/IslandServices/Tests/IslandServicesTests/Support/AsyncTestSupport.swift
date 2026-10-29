/// Lets queued main-actor work run and async calls that hop to the global executor (fakes, permission checks)
/// finish and hop back. Spins for a fixed window so it holds up when parallel tests load the machine.
func settle(_ iterations: Int = 10) async {
    let deadline = ContinuousClock.now + .milliseconds(200)
    while ContinuousClock.now < deadline {
        for _ in 0..<iterations { await Task.yield() }
        try? await Task.sleep(for: .milliseconds(5))
    }
}
