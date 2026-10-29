/// Runs one AppleScript source synchronously (blocking). Only ScriptRunner calls it, off the main thread.
public protocol ScriptExecuting: Sendable {
    func execute(_ source: String) -> ScriptOutcome
}
