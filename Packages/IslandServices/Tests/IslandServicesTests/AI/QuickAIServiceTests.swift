import Foundation
import IslandCore
import Testing

@testable import IslandServices

@Suite(.serialized) struct QuickAIServiceTests {
    @Test @MainActor func ollamaRequestAndResponseWithoutAPIKey() async throws {
        let secrets = InMemorySecretStore()
        let (session, sessionID) = StubURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:11434/api/generate")
            #expect(request.httpMethod == "POST")
            if let body = StubURLProtocol.readBody(from: request),
                let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            {
                #expect(json["model"] as? String == "llama3.2")
                #expect(json["prompt"] as? String == "What is Swift?")
                #expect(json["stream"] as? Bool == false)
            } else {
                Issue.record("Expected JSON body for Ollama request")
            }
            let payload = Data(#"{"response":"Swift is a compiled language by Apple."}"#.utf8)
            return (200, payload)
        }
        defer { StubURLProtocol.unregister(sessionID) }

        let service = QuickAIService(session: session, secrets: secrets)
        #expect(service.hasAPIKey(for: .ollama) == true)

        await service.ask("What is Swift?", config: QuickAIConfig(provider: .ollama))

        #expect(service.lastError == nil)
        #expect(service.isGenerating == false)
        #expect(service.messages.count == 2)
        #expect(service.messages[0].role == "user")
        #expect(service.messages[0].text == "What is Swift?")
        #expect(service.messages[1].role == "assistant")
        #expect(service.messages[1].text == "Swift is a compiled language by Apple.")
    }

    @Test @MainActor func openAIAndGeminiHeadersAndResponsesWithSecretStore() async throws {
        let secrets = InMemorySecretStore()
        let (session, sessionID) = StubURLProtocol.makeSession { request in
            let urlString = request.url?.absoluteString ?? ""
            if urlString == "https://api.openai.com/v1/chat/completions" {
                #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test-openai")
                let payload = Data(
                    #"{"choices":[{"message":{"content":"Actors isolate mutable state."}}]}"#.utf8)
                return (200, payload)
            }
            if urlString == "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent" {
                #expect(request.value(forHTTPHeaderField: "x-goog-api-key") == "AIza-test-gemini")
                #expect(urlString.contains("AIza") == false)
                let payload = Data(
                    #"{"candidates":[{"content":{"parts":[{"text":"Gemini reply text."}]}}]}"#.utf8)
                return (200, payload)
            }
            return (404, Data())
        }
        defer { StubURLProtocol.unregister(sessionID) }

        let service = QuickAIService(session: session, secrets: secrets)
        service.saveAPIKey("sk-test-openai", for: .openAI)
        service.saveAPIKey("AIza-test-gemini", for: .gemini)
        #expect(service.hasAPIKey(for: .openAI) == true)
        #expect(service.hasAPIKey(for: .gemini) == true)

        await service.ask("Explain actors", config: QuickAIConfig(provider: .openAI))
        #expect(service.lastError == nil)
        #expect(service.messages.last?.text == "Actors isolate mutable state.")

        await service.ask("Hi Gemini", config: QuickAIConfig(provider: .gemini))
        #expect(service.lastError == nil)
        #expect(service.messages.last?.text == "Gemini reply text.")

        service.clearAPIKey(for: .openAI)
        #expect(service.hasAPIKey(for: .openAI) == false)
    }

    @Test @MainActor func missingAPIKeyForOpenAISetsErrorWithoutNetworkCall() async {
        let secrets = InMemorySecretStore()
        let counter = CallCounter()
        let (session, sessionID) = StubURLProtocol.makeSession { _ in
            counter.increment()
            return (200, Data())
        }
        defer { StubURLProtocol.unregister(sessionID) }

        let service = QuickAIService(session: session, secrets: secrets)
        #expect(service.hasAPIKey(for: .openAI) == false)

        await service.ask("Hello", config: QuickAIConfig(provider: .openAI))

        #expect(counter.count == 0)
        #expect(service.lastError != nil)
        #expect(service.messages.isEmpty)
        #expect(service.isGenerating == false)
    }
}

private final class InMemorySecretStore: SecretStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: String] = [:]

    func read(account: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return values[account]
    }

    func save(_ secret: String, account: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        values[account] = secret
        return true
    }

    func delete(account: String) {
        lock.lock()
        defer { lock.unlock() }
        values.removeValue(forKey: account)
    }
}

private final class CallCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func increment() {
        lock.lock()
        defer { lock.unlock() }
        value += 1
    }
}

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) -> (Int, Data)

    private static let headerName = "X-Lunula-Test-Session"
    private static let registry = HandlerRegistry()

    static func makeSession(handler: @escaping Handler) -> (URLSession, String) {
        let id = UUID().uuidString
        registry.set(handler, for: id)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        config.httpAdditionalHeaders = [headerName: id]
        return (URLSession(configuration: config), id)
    }

    static func unregister(_ id: String) {
        registry.remove(id)
    }

    static func readBody(from request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var output = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read > 0 {
                output.append(buffer, count: read)
            } else {
                break
            }
        }
        return output
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard
            let sessionID = request.value(forHTTPHeaderField: Self.headerName),
            let handler = Self.registry.get(sessionID),
            let url = request.url
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let (status, data) = handler(request)
        guard
            let response = HTTPURLResponse(
                url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class HandlerRegistry: @unchecked Sendable {
    private let lock = NSLock()
    private var handlers: [String: StubURLProtocol.Handler] = [:]

    func set(_ handler: @escaping StubURLProtocol.Handler, for id: String) {
        lock.lock()
        defer { lock.unlock() }
        handlers[id] = handler
    }

    func get(_ id: String) -> StubURLProtocol.Handler? {
        lock.lock()
        defer { lock.unlock() }
        return handlers[id]
    }

    func remove(_ id: String) {
        lock.lock()
        defer { lock.unlock() }
        handlers.removeValue(forKey: id)
    }
}
