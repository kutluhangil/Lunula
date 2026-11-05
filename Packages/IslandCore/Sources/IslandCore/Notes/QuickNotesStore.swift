import Foundation
import Observation

public struct QuickNote: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var text: String
    public var createdAt: Date

    public init(id: UUID = UUID(), text: String, createdAt: Date) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }
}

/// Lightweight scratchpad persisted in UserDefaults for instant jotting inside the expanded island.
@MainActor @Observable public final class QuickNotesStore {
    static let defaultsKey = "quickNotes.v1"
    public static let maxNotes = 20

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let time: IslandTime
    public private(set) var notes: [QuickNote] = []

    public init(defaults: UserDefaults, time: IslandTime) {
        self.defaults = defaults
        self.time = time
        if let data = defaults.data(forKey: Self.defaultsKey),
            let decoded = try? JSONDecoder().decode([QuickNote].self, from: data)
        {
            notes = decoded
        }
    }

    public func add(_ rawText: String) {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        notes.insert(QuickNote(text: trimmed, createdAt: time.now), at: 0)
        if notes.count > Self.maxNotes {
            notes = Array(notes.prefix(Self.maxNotes))
        }
        persist()
    }

    public func remove(_ id: UUID) {
        notes.removeAll { $0.id == id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(notes) {
            defaults.set(data, forKey: Self.defaultsKey)
        }
    }
}
