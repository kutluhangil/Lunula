import Foundation
import IslandCore
import Observation

/// Lightweight in-notch Quick Ask client supporting local Ollama (zero key) and BYOK cloud providers via Keychain.
@MainActor @Observable public final class QuickAIService {
    private static let systemInstruction =
        "Answer concisely in plain text (max 3 short sentences) in the user's language."

    @ObservationIgnored private let session: URLSession
    @ObservationIgnored private let secrets: SecretStoring

    public private(set) var messages: [QuickAIMessage] = []
    public private(set) var isGenerating = false
    public private(set) var lastError: String?

    public init(session: URLSession = .shared, secrets: SecretStoring = KeychainSecretStore()) {
        self.session = session
        self.secrets = secrets
    }

    public func hasAPIKey(for provider: QuickAIProvider) -> Bool {
        guard provider.requiresAPIKey else { return true }
        guard let stored = secrets.read(account: provider.rawValue) else { return false }
        return !stored.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func saveAPIKey(_ key: String, for provider: QuickAIProvider) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            secrets.delete(account: provider.rawValue)
        } else {
            _ = secrets.save(trimmed, account: provider.rawValue)
        }
        lastError = nil
    }

    public func clearAPIKey(for provider: QuickAIProvider) {
        secrets.delete(account: provider.rawValue)
    }

    public func clearConversation() {
        messages.removeAll()
        lastError = nil
    }

    public func ask(_ prompt: String, config: QuickAIConfig) async {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty, !isGenerating else { return }

        let apiKey: String?
        if config.provider.requiresAPIKey {
            guard
                let stored = secrets.read(account: config.provider.rawValue)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                !stored.isEmpty
            else {
                lastError = "Missing API key for \(config.provider.displayName)."
                return
            }
            apiKey = stored
        } else {
            apiKey = nil
        }

        lastError = nil
        messages.append(QuickAIMessage(role: "user", text: trimmedPrompt))
        isGenerating = true
        defer { isGenerating = false }

        do {
            let request = try Self.buildRequest(
                prompt: trimmedPrompt, config: config, apiKey: apiKey)
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                lastError = "Invalid server response."
                return
            }
            guard (200..<300).contains(http.statusCode) else {
                lastError =
                    Self.parseServerError(data: data)
                    ?? "HTTP \(http.statusCode) from \(config.provider.displayName)."
                return
            }
            let reply = try Self.parseReply(data: data, provider: config.provider)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !reply.isEmpty else {
                lastError = "Empty response from \(config.provider.displayName)."
                return
            }
            messages.append(QuickAIMessage(role: "assistant", text: reply))
        } catch {
            lastError = error.localizedDescription
        }
    }

    private static func buildRequest(
        prompt: String, config: QuickAIConfig, apiKey: String?
    ) throws -> URLRequest {
        let model = config.resolvedModel
        let encoder = JSONEncoder()

        switch config.provider {
        case .ollama:
            let rawBase = config.ollamaEndpoint
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let base = rawBase.isEmpty ? "http://127.0.0.1:11434" : rawBase
            guard let url = URL(string: "\(base)/api/generate") else {
                throw URLError(.badURL)
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 30
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(
                OllamaRequest(model: model, prompt: prompt, system: systemInstruction, stream: false))
            return request

        case .openAI:
            guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
                throw URLError(.badURL)
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 30
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let apiKey {
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            }
            request.httpBody = try encoder.encode(
                OpenAIRequest(
                    model: model,
                    messages: [
                        .init(role: "system", content: systemInstruction),
                        .init(role: "user", content: prompt),
                    ]))
            return request

        case .anthropic:
            guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
                throw URLError(.badURL)
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 30
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let apiKey {
                request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            }
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.httpBody = try encoder.encode(
                AnthropicRequest(
                    model: model,
                    system: systemInstruction,
                    maxTokens: 300,
                    messages: [.init(role: "user", content: prompt)]))
            return request

        case .gemini:
            let encodedModel = model.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? model
            guard
                let url = URL(
                    string: "https://generativelanguage.googleapis.com/v1beta/models/\(encodedModel):generateContent")
            else {
                throw URLError(.badURL)
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 30
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let apiKey {
                request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
            }
            request.httpBody = try encoder.encode(
                GeminiRequest(
                    systemInstruction: .init(role: nil, parts: [.init(text: systemInstruction)]),
                    contents: [.init(role: "user", parts: [.init(text: prompt)])]))
            return request
        }
    }

    private static func parseReply(data: Data, provider: QuickAIProvider) throws -> String {
        let decoder = JSONDecoder()
        switch provider {
        case .ollama:
            let decoded = try decoder.decode(OllamaResponse.self, from: data)
            return decoded.response ?? ""
        case .openAI:
            let decoded = try decoder.decode(OpenAIResponse.self, from: data)
            return decoded.choices?.first?.message.content ?? ""
        case .anthropic:
            let decoded = try decoder.decode(AnthropicResponse.self, from: data)
            return decoded.content?.first?.text ?? ""
        case .gemini:
            let decoded = try decoder.decode(GeminiResponse.self, from: data)
            return decoded.candidates?.first?.content?.parts?.first?.text ?? ""
        }
    }

    private static func parseServerError(data: Data) -> String? {
        if let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data),
            let msg = envelope.error?.message, !msg.isEmpty
        {
            return msg
        }
        if let flat = try? JSONDecoder().decode(FlatErrorEnvelope.self, from: data),
            let msg = flat.error, !msg.isEmpty
        {
            return msg
        }
        return nil
    }
}

private struct OllamaRequest: Encodable {
    var model: String
    var prompt: String
    var system: String
    var stream: Bool
}

private struct OllamaResponse: Decodable {
    var response: String?
}

private struct OpenAIRequest: Encodable {
    struct Message: Encodable {
        var role: String
        var content: String
    }
    var model: String
    var messages: [Message]
}

private struct OpenAIResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            var content: String?
        }
        var message: Message
    }
    var choices: [Choice]?
}

private struct AnthropicRequest: Encodable {
    struct Message: Encodable {
        var role: String
        var content: String
    }
    var model: String
    var system: String
    var maxTokens: Int
    var messages: [Message]

    enum CodingKeys: String, CodingKey {
        case model
        case system
        case maxTokens = "max_tokens"
        case messages
    }
}

private struct AnthropicResponse: Decodable {
    struct ContentBlock: Decodable {
        var text: String?
    }
    var content: [ContentBlock]?
}

private struct GeminiRequest: Encodable {
    struct Part: Encodable {
        var text: String
    }
    struct Content: Encodable {
        var role: String?
        var parts: [Part]
    }
    var systemInstruction: Content
    var contents: [Content]

    enum CodingKeys: String, CodingKey {
        case systemInstruction = "system_instruction"
        case contents
    }
}

private struct GeminiResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable {
                var text: String?
            }
            var parts: [Part]?
        }
        var content: Content?
    }
    var candidates: [Candidate]?
}

private struct ErrorEnvelope: Decodable {
    struct Detail: Decodable {
        var message: String?
    }
    var error: Detail?
}

private struct FlatErrorEnvelope: Decodable {
    var error: String?
}
