import Foundation
import Observation

public struct QuickReminderItem: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var isCompleted: Bool
    public var createdAt: Date

    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false, createdAt: Date) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

/// Persists quick reminders and checklist items inside the island without requiring extra TCC prompts.
@MainActor @Observable public final class QuickRemindersStore {
    static let storageKey = "reminders.items.v1"

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let time: IslandTime
    public private(set) var items: [QuickReminderItem] = []

    public init(defaults: UserDefaults, time: IslandTime) {
        self.defaults = defaults
        self.time = time
        if let data = defaults.data(forKey: Self.storageKey),
            let decoded = try? JSONDecoder().decode([QuickReminderItem].self, from: data)
        {
            items = decoded
        }
    }

    public func add(_ rawTitle: String) {
        let trimmed = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.insert(QuickReminderItem(title: trimmed, isCompleted: false, createdAt: time.now), at: 0)
        persist()
    }

    public func toggle(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isCompleted.toggle()
        persist()
    }

    public func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }

    public func clearCompleted() {
        items.removeAll(where: \.isCompleted)
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
