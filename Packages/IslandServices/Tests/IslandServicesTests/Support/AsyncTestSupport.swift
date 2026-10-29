/// Lets queued main-actor work run; the short sleep also lets async calls that hop to the global executor
/// (fake sources, permission checks) finish and hop back.
func settle(_ iterations: Int = 10) async {
    for _ in 0..<iterations { await Task.yield() }
    try? await Task.sleep(for: .milliseconds(30))
    for _ in 0..<iterations { await Task.yield() }
}
