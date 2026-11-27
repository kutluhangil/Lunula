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
    public private(set) var availableOllamaModels: [String] = []
    public private(set) var isTestingConnection = false
    public private(set) var connectionStatusMessage: String?
    public private(set) var connectionSucceeded: Bool?

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

    @discardableResult
    public func fetchOllamaModels(endpoint: String) async -> [String] {
        do {
            let request = try Self.buildOllamaTagsRequest(endpoint: endpoint)
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return []
            }
            let models = try Self.parseOllamaModels(data: data)
            availableOllamaModels = models
            return models
        } catch {
            return []
        }
    }

    @discardableResult
    public func testConnection(config: QuickAIConfig) async -> Bool {
        isTestingConnection = true
        defer { isTestingConnection = false }

        if config.provider == .ollama {
            do {
                let request = try Self.buildOllamaTagsRequest(endpoint: config.ollamaEndpoint)
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    connectionSucceeded = false
                    connectionStatusMessage = "Invalid server response."
                    return false
                }
                guard (200..<300).contains(http.statusCode) else {
                    connectionSucceeded = false
                    connectionStatusMessage =
                        Self.parseServerError(data: data)
                        ?? "HTTP \(http.statusCode) from \(config.provider.displayName)."
                    return false
                }
                let models = try Self.parseOllamaModels(data: data)
                availableOllamaModels = models
                connectionSucceeded = true
                connectionStatusMessage = "Ollama connected (\(availableOllamaModels.count) models)"
                return true
            } catch {
                connectionSucceeded = false
                connectionStatusMessage = error.localizedDescription
                return false
            }
        }

        guard
            let key = secrets.read(account: config.provider.rawValue)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            !key.isEmpty
        else {
            connectionSucceeded = false
            connectionStatusMessage = "Missing API key"
            return false
        }

        do {
            let request = try Self.buildRequest(
                prompt: "Ping", config: config, apiKey: key, stream: false)
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                connectionSucceeded = false
                connectionStatusMessage = "Invalid server response."
                return false
            }
            guard (200..<300).contains(http.statusCode) else {
                connectionSucceeded = false
                connectionStatusMessage =
                    Self.parseServerError(data: data)
                    ?? "HTTP \(http.statusCode) from \(config.provider.displayName)."
                return false
            }
            let reply = try Self.parseReply(data: data, provider: config.provider)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !reply.isEmpty else {
                connectionSucceeded = false
                connectionStatusMessage = "Empty response from \(config.provider.displayName)."
                return false
            }
            connectionSucceeded = true
            connectionStatusMessage = "\(config.provider.displayName) connected"
            return true
        } catch {
            connectionSucceeded = false
            connectionStatusMessage = error.localizedDescription
            return false
        }
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

        let assistantID = UUID()
        var didAppendPlaceholder = false
        var accumulatedText = ""

        do {
            let request = try Self.buildRequest(
                prompt: trimmedPrompt, config: config, apiKey: apiKey, stream: true)
            let (bytes, response) = try await session.bytes(for: request)
            guard let http = response as? HTTPURLResponse else {
                lastError = "Invalid server response."
                return
            }
            guard (200..<300).contains(http.statusCode) else {
                var errorData = Data()
                for try await byte in bytes {
                    errorData.append(byte)
                }
                lastError =
                    Self.parseServerError(data: errorData)
                    ?? "HTTP \(http.statusCode) from \(config.provider.displayName)."
                return
            }

            var handledAsStream = false
            var fallbackLines: [String] = []

            for try await rawLine in bytes.lines {
                let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    continue
                }

                if trimmed.hasPrefix("event:")
                    || trimmed.hasPrefix("id:")
                    || trimmed.hasPrefix("retry:")
                    || trimmed.hasPrefix(":")
                {
                    continue
                }

                if trimmed.hasPrefix("data:") {
                    handledAsStream = true
                    let payload = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                    if payload.isEmpty || payload == "[DONE]" {
                        continue
                    }
                    if let delta = try Self.parseSSEDelta(payload: payload, provider: config.provider),
                        !delta.isEmpty
                    {
                        appendDelta(
                            delta,
                            assistantID: assistantID,
                            didAppendPlaceholder: &didAppendPlaceholder,
                            accumulatedText: &accumulatedText
                        )
                    }
                    continue
                }

                if config.provider == .ollama,
                    let outcome = try Self.parseOllamaLine(trimmed)
                {
                    handledAsStream = true
                    if let delta = outcome.delta, !delta.isEmpty {
                        appendDelta(
                            delta,
                            assistantID: assistantID,
                            didAppendPlaceholder: &didAppendPlaceholder,
                            accumulatedText: &accumulatedText
                        )
                    }
                    continue
                }

                fallbackLines.append(rawLine)
            }

            if !handledAsStream, !fallbackLines.isEmpty {
                let fallbackBuffer = fallbackLines.joined(separator: "\n")
                accumulatedText = try Self.parseReply(
                    data: Data(fallbackBuffer.utf8), provider: config.provider)
            }

            let finalReply = accumulatedText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !finalReply.isEmpty else {
                if didAppendPlaceholder {
                    messages.removeAll { $0.id == assistantID }
                }
                lastError = "Empty response from \(config.provider.displayName)."
                return
            }

            if didAppendPlaceholder {
                if let index = messages.lastIndex(where: { $0.id == assistantID }) {
                    messages[index].text = finalReply
                }
            } else {
                messages.append(QuickAIMessage(id: assistantID, role: "assistant", text: finalReply))
            }
        } catch {
            if didAppendPlaceholder,
                accumulatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                messages.removeAll { $0.id == assistantID }
            }
            lastError = error.localizedDescription
        }
    }

    private func appendDelta(
        _ delta: String,
        assistantID: UUID,
        didAppendPlaceholder: inout Bool,
        accumulatedText: inout String
    ) {
        if !didAppendPlaceholder {
            messages.append(QuickAIMessage(id: assistantID, role: "assistant", text: ""))
            didAppendPlaceholder = true
        }
        accumulatedText += delta
        if let index = messages.lastIndex(where: { $0.id == assistantID }) {
            messages[index].text = accumulatedText
        }
    }

    private static func normalizedOllamaBase(_ endpoint: String) -> String {
        let rawBase =
            endpoint
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return rawBase.isEmpty ? "http://127.0.0.1:11434" : rawBase
    }

    private static func buildOllamaTagsRequest(endpoint: String) throws -> URLRequest {
        let base = normalizedOllamaBase(endpoint)
        guard let url = URL(string: "\(base)/api/tags") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 6
        return request
    }

    private static func parseOllamaModels(data: Data) throws -> [String] {
        let decoded = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
        var seen = Set<String>()
        var names: [String] = []
        for entry in decoded.models ?? [] {
            guard
                let name = entry.name?.trimmingCharacters(in: .whitespacesAndNewlines),
                !name.isEmpty
            else {
                continue
            }
            if seen.insert(name).inserted {
                names.append(name)
            }
        }
        return names
    }

    private static func buildRequest(
        prompt: String, config: QuickAIConfig, apiKey: String?, stream: Bool
    ) throws -> URLRequest {
        let model = config.resolvedModel
        let encoder = JSONEncoder()

        switch config.provider {
        case .ollama:
            let base = normalizedOllamaBase(config.ollamaEndpoint)
            guard let url = URL(string: "\(base)/api/generate") else {
                throw URLError(.badURL)
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 30
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(
                OllamaRequest(
                    model: model, prompt: prompt, system: systemInstruction, stream: stream))
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
                    stream: stream,
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
                    stream: stream,
                    messages: [.init(role: "user", content: prompt)]))
            return request

        case .gemini:
            let encodedModel =
                model.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? model
            let endpointAction = stream ? "streamGenerateContent?alt=sse" : "generateContent"
            guard
                let url = URL(
                    string:
                        "https://generativelanguage.googleapis.com/v1beta/models/\(encodedModel):\(endpointAction)"
                )
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

    private static func parseOllamaLine(_ line: String) throws -> (delta: String?, done: Bool)? {
        let data = Data(line.utf8)
        guard let decoded = try? JSONDecoder().decode(OllamaStreamChunk.self, from: data) else {
            return nil
        }
        if let errorMessage = decoded.error, !errorMessage.isEmpty {
            throw QuickAIStreamError(message: errorMessage)
        }
        guard decoded.response != nil || decoded.done != nil else {
            return nil
        }
        return (decoded.response, decoded.done ?? false)
    }

    private static func parseSSEDelta(
        payload: String, provider: QuickAIProvider
    ) throws -> String? {
        let data = Data(payload.utf8)
        let decoder = JSONDecoder()

        switch provider {
        case .ollama:
            let decoded = try decoder.decode(OllamaStreamChunk.self, from: data)
            if let errorMessage = decoded.error, !errorMessage.isEmpty {
                throw QuickAIStreamError(message: errorMessage)
            }
            return decoded.response

        case .openAI:
            let decoded = try decoder.decode(OpenAIStreamChunk.self, from: data)
            guard let choice = decoded.choices?.first else {
                if let errorMessage = parseServerError(data: data) {
                    throw QuickAIStreamError(message: errorMessage)
                }
                return nil
            }
            return choice.delta?.content ?? choice.message?.content

        case .anthropic:
            let decoded = try decoder.decode(AnthropicStreamChunk.self, from: data)
            if decoded.type == "error", let errorMessage = parseServerError(data: data) {
                throw QuickAIStreamError(message: errorMessage)
            }
            if decoded.type == "content_block_delta" {
                return decoded.delta?.text
            }
            if decoded.type == nil || decoded.type == "message" {
                return decoded.content?.first?.text
            }
            return nil

        case .gemini:
            let decoded = try decoder.decode(GeminiResponse.self, from: data)
            if decoded.candidates == nil, let errorMessage = parseServerError(data: data) {
                throw QuickAIStreamError(message: errorMessage)
            }
            return extractGeminiText(from: decoded)
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
            if let decoded = try? decoder.decode(GeminiResponse.self, from: data) {
                return extractGeminiText(from: decoded)
            }
            let arrayDecoded = try decoder.decode([GeminiResponse].self, from: data)
            var combined = ""
            for item in arrayDecoded {
                combined += extractGeminiText(from: item)
            }
            return combined
        }
    }

    private static func extractGeminiText(from response: GeminiResponse) -> String {
        guard let parts = response.candidates?.first?.content?.parts else { return "" }
        var output = ""
        for part in parts {
            if let text = part.text {
                output += text
            }
        }
        return output
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

private struct QuickAIStreamError: LocalizedError, Sendable {
    let message: String

    var errorDescription: String? {
        message
    }
}

private struct OllamaTagsResponse: Decodable {
    struct ModelEntry: Decodable {
        var name: String?
    }
    var models: [ModelEntry]?
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

private struct OllamaStreamChunk: Decodable {
    var response: String?
    var done: Bool?
    var error: String?
}

private struct OpenAIRequest: Encodable {
    struct Message: Encodable {
        var role: String
        var content: String
    }
    var model: String
    var stream: Bool
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

private struct OpenAIStreamChunk: Decodable {
    struct Choice: Decodable {
        struct ContentPayload: Decodable {
            var content: String?
        }
        var delta: ContentPayload?
        var message: ContentPayload?
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
    var stream: Bool
    var messages: [Message]

    enum CodingKeys: String, CodingKey {
        case model
        case system
        case maxTokens = "max_tokens"
        case stream
        case messages
    }
}

private struct AnthropicResponse: Decodable {
    struct ContentBlock: Decodable {
        var text: String?
    }
    var content: [ContentBlock]?
}

private struct AnthropicStreamChunk: Decodable {
    struct Delta: Decodable {
        var type: String?
        var text: String?
    }
    struct ContentBlock: Decodable {
        var text: String?
    }
    var type: String?
    var delta: Delta?
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
