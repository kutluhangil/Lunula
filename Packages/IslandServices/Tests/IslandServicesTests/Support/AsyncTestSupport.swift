func settle(_ iterations: Int = 10) async {
    for _ in 0..<iterations { await Task.yield() }
}
