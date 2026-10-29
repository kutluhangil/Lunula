import Foundation

public enum ScriptValue: Equatable, Sendable {
    case text(String)
    case number(Double)
    case bool(Bool)
    case data(Data)
    case list([ScriptValue])
    case none
}

public enum ScriptOutcome: Equatable, Sendable {
    case success(ScriptValue)
    case notRunning
    case permissionNeeded
    case permissionDenied
    case timedOut
    case failed(code: Int)
}
