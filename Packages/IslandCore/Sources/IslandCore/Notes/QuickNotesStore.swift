import Foundation
import Observation

public struct QuickNote: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var text: String
    public var createdAt: Date
    public var isPinned: Bool

    public init(id: UUID = UUID(), text: String, createdAt: Date, isPinned: Bool = false) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.isPinned = isPinned
    }

    private enum CodingKeys: String, CodingKey {
        case id, text, createdAt, isPinned
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        text = try c.decode(String.self, forKey: .text)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        isPinned = (try? c.decodeIfPresent(Bool.self, forKey: .isPinned)) ?? false
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
            notes = Self.ordered(decoded)
        }
    }

    public func add(_ rawText: String) {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        notes.insert(QuickNote(text: trimmed, createdAt: time.now), at: 0)
        notes = Self.ordered(notes)
        trimToMax()
        persist()
    }

    public func togglePin(_ id: UUID) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].isPinned.toggle()
        notes = Self.ordered(notes)
        persist()
    }

    public func remove(_ id: UUID) {
        notes.removeAll { $0.id == id }
        persist()
    }

    private func trimToMax() {
        while notes.count > Self.maxNotes {
            if let lastUnpinned = notes.lastIndex(where: { !$0.isPinned }) {
                notes.remove(at: lastUnpinned)
            } else {
                notes.removeLast()
            }
        }
    }

    private static func ordered(_ items: [QuickNote]) -> [QuickNote] {
        let pinned = items.filter(\.isPinned)
        let unpinned = items.filter { !$0.isPinned }
        return pinned + unpinned
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(notes) {
            defaults.set(data, forKey: Self.defaultsKey)
        }
    }
}
