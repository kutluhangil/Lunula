import Foundation

public enum QuickAIProvider: String, Codable, Equatable, Sendable, CaseIterable {
    case ollama
    case openAI
    case anthropic
    case gemini

    public var displayName: String {
        switch self {
        case .ollama: "Ollama (Local)"
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic"
        case .gemini: "Gemini"
        }
    }

    public var defaultModel: String {
        switch self {
        case .ollama: "llama3.2"
        case .openAI: "gpt-4o-mini"
        case .anthropic: "claude-3-5-haiku-latest"
        case .gemini: "gemini-2.5-flash"
        }
    }

    public var requiresAPIKey: Bool {
        self != .ollama
    }
}

public struct QuickAIConfig: Codable, Equatable, Sendable {
    public var provider: QuickAIProvider
    public var model: String
    public var ollamaEndpoint: String

    public init(
        provider: QuickAIProvider = .ollama,
        model: String = "",
        ollamaEndpoint: String = "http://127.0.0.1:11434"
    ) {
        self.provider = provider
        self.model = model
        self.ollamaEndpoint = ollamaEndpoint
    }

    public var resolvedModel: String {
        let trimmed = model.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? provider.defaultModel : trimmed
    }
}

public struct QuickAIMessage: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var role: String
    public var text: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        role: String,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}
