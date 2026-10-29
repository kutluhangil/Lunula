import AppIntents
import IslandCore

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case invalid(IslandURLError)
    case notFound(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalid(.missingParameter(let name)): "intent.error.missing \(name)"
        case .invalid(.invalidParameter(let name)): "intent.error.invalid \(name)"
        case .invalid: "intent.error.generic"
        case .notFound(let id): "intent.error.notFound \(id)"
        }
    }
}

/// Toggles the island on the screen under the mouse (registered as an App Intents dependency).
@MainActor final class IslandToggler {
    private let action: @MainActor () -> Void
    init(_ toggle: @escaping @MainActor () -> Void) { action = toggle }
    func toggle() { action() }
}
