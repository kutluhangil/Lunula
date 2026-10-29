import Foundation
import IslandCore

public protocol ArtworkAccentProviding: Sendable {
    func accent(for key: String, data: @Sendable () async -> Data?) async -> RGBAColor?
}

/// Accent per artwork key, computed once off the main thread; keeps the 50 most recently used results.
public actor ArtworkAccentStore: ArtworkAccentProviding {
    static let capacity = 50
    private var cache: [String: RGBAColor?] = [:]
    private var order: [String] = []

    public init() {}

    public func accent(for key: String, data: @Sendable () async -> Data?) async -> RGBAColor? {
        if let hit = cache[key] {
            touch(key)
            return hit
        }
        guard let bytes = await data() else { return nil }
        let accent = ArtworkPalette.accent(from: ArtworkColorExtractor.weightedColors(from: bytes))
        cache[key] = accent
        touch(key)
        if order.count > Self.capacity { cache[order.removeFirst()] = nil }
        return accent
    }

    private func touch(_ key: String) {
        order.removeAll { $0 == key }
        order.append(key)
    }
}
