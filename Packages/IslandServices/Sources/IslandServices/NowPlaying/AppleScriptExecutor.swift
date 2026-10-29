import Foundation

/// NSAppleScript with a compiled-script cache keyed by source text.
public final class AppleScriptExecutor: ScriptExecuting, @unchecked Sendable {  // cache guarded by `lock`
    private let lock = NSLock()
    private var cache: [String: NSAppleScript] = [:]

    public init() {}

    public func execute(_ source: String) -> ScriptOutcome {
        let script: NSAppleScript? = lock.withLock {
            if let cached = cache[source] { return cached }
            let compiled = NSAppleScript(source: source)
            cache[source] = compiled
            return compiled
        }
        guard let script else { return .failed(code: -1) }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if let error {
            return Self.outcome(forErrorCode: (error[NSAppleScript.errorNumber] as? Int) ?? -1)
        }
        return .success(Self.value(result))
    }

    public static func outcome(forErrorCode code: Int) -> ScriptOutcome {
        switch code {
        case -1743: .permissionDenied
        case -1744: .permissionNeeded
        case -600: .notRunning
        case -1712: .timedOut
        default: .failed(code: code)
        }
    }

    static func value(_ d: NSAppleEventDescriptor) -> ScriptValue {
        switch d.descriptorType {
        case typeAEList:
            return .list(d.numberOfItems == 0 ? [] : (1...d.numberOfItems).compactMap { d.atIndex($0) }.map(value))
        case typeUnicodeText, typeUTF8Text, typeChar, typeEnumerated, typeType:
            return d.stringValue.map(ScriptValue.text) ?? .none
        case typeSInt16, typeSInt32, typeSInt64, typeUInt32, typeIEEE32BitFloatingPoint, typeIEEE64BitFloatingPoint:
            return .number(d.doubleValue)
        case typeBoolean, typeTrue, typeFalse:
            return .bool(d.booleanValue)
        case typeNull:
            return .none
        default:
            // Raw data, pictures and anything else opaque.
            return d.data.isEmpty ? .none : .data(d.data)
        }
    }
}
