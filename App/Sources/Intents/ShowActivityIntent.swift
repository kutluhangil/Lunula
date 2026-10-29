import AppIntents
import IslandCore

struct ShowActivityIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.show.title"
    static let supportedModes: IntentModes = .background

    @Parameter(title: "intent.param.id") var id: String
    @Parameter(title: "intent.param.title") var title: String
    @Parameter(title: "intent.param.subtitle") var subtitle: String?
    @Parameter(title: "intent.param.symbol") var symbol: String?
    @Parameter(title: "intent.param.accent") var accentHex: String?
    @Parameter(title: "intent.param.progress") var progress: Double?
    @Parameter(title: "intent.param.duration") var durationSeconds: Double?

    @Dependency private var custom: CustomActivityController

    @MainActor func perform() async throws -> some IntentResult { try await perform(using: custom) }

    @MainActor func perform(using custom: CustomActivityController) async throws -> some IntentResult {
        custom.show(try request())
        return .result()
    }

    func request() throws -> CustomActivityRequest {
        switch CustomActivityRequest.make(
            id: id, title: title, subtitle: subtitle, symbol: symbol, accentHex: accentHex, progress: progress,
            duration: durationSeconds)
        {
        case .success(let request): return request
        case .failure(let error): throw IntentError.invalid(error)
        }
    }
}

struct UpdateActivityIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.update.title"
    static let supportedModes: IntentModes = .background

    @Parameter(title: "intent.param.id") var id: String
    @Parameter(title: "intent.param.title") var title: String
    @Parameter(title: "intent.param.subtitle") var subtitle: String?
    @Parameter(title: "intent.param.symbol") var symbol: String?
    @Parameter(title: "intent.param.accent") var accentHex: String?
    @Parameter(title: "intent.param.progress") var progress: Double?
    @Parameter(title: "intent.param.duration") var durationSeconds: Double?

    @Dependency private var custom: CustomActivityController

    @MainActor func perform() async throws -> some IntentResult { try await perform(using: custom) }

    @MainActor func perform(using custom: CustomActivityController) async throws -> some IntentResult {
        guard custom.contains(id: id) else { throw IntentError.notFound(id) }
        switch CustomActivityRequest.make(
            id: id, title: title, subtitle: subtitle, symbol: symbol, accentHex: accentHex, progress: progress,
            duration: durationSeconds)
        {
        case .success(let request): custom.show(request)
        case .failure(let error): throw IntentError.invalid(error)
        }
        return .result()
    }
}

struct EndActivityIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.end.title"
    static let supportedModes: IntentModes = .background

    @Parameter(title: "intent.param.id") var id: String

    @Dependency private var custom: CustomActivityController

    @MainActor func perform() async throws -> some IntentResult {
        custom.end(id: id)
        return .result()
    }
}
