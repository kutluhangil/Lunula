import Foundation
import Observation

public enum ClipboardSmartKind: Equatable, Sendable, Codable {
    case plainText
    case url(URL)
    case email(String)
    case hexColor(RGBAColor)

    public static func detect(_ raw: String) -> ClipboardSmartKind {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let color = RGBAColor(hex: trimmed) {
            return .hexColor(color)
        }
        if trimmed.contains("@"), !trimmed.contains(" "),
            let mailURL = URL(string: "mailto:\(trimmed)"), mailURL.scheme == "mailto"
        {
            let parts = trimmed.split(separator: "@")
            if parts.count == 2, parts[1].contains(".") {
                return .email(trimmed)
            }
        }
        if let url = URL(string: trimmed),
            let scheme = url.scheme?.lowercased(),
            scheme == "https" || scheme == "http"
        {
            return .url(url)
        }
        return .plainText
    }
}

public struct ClipboardEntry: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var text: String
    public var isPinned: Bool
    public var createdAt: Date
    public var smartKind: ClipboardSmartKind

    public init(id: UUID = UUID(), text: String, isPinned: Bool = false, createdAt: Date) {
        self.id = id
        self.text = text
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.smartKind = ClipboardSmartKind.detect(text)
    }
}

public struct TextSnippet: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var body: String

    public init(id: UUID = UUID(), title: String, body: String) {
        self.id = id
        self.title = title
        self.body = body
    }
}

/// Manages clipboard history (with pins surviving clear and cap) and reusable text snippets.
@MainActor @Observable public final class ClipboardHistoryStore {
    static let entriesKey = "clipboard.entries.v1"
    static let snippetsKey = "clipboard.snippets.v1"
    public static let maxUnpinned = 25

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let time: IslandTime
    public private(set) var entries: [ClipboardEntry] = []
    public private(set) var snippets: [TextSnippet] = []

    public init(defaults: UserDefaults, time: IslandTime) {
        self.defaults = defaults
        self.time = time
        if let data = defaults.data(forKey: Self.entriesKey),
            let decoded = try? JSONDecoder().decode([ClipboardEntry].self, from: data)
        {
            entries = decoded
        }
        if let data = defaults.data(forKey: Self.snippetsKey),
            let decoded = try? JSONDecoder().decode([TextSnippet].self, from: data)
        {
            snippets = decoded
        }
    }

    public func record(_ rawText: String) {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let existingIdx = entries.firstIndex(where: { $0.text == trimmed }) {
            var existing = entries.remove(at: existingIdx)
            existing.createdAt = time.now
            entries.insert(existing, at: 0)
            persistEntries()
            return
        }
        entries.insert(ClipboardEntry(text: trimmed, isPinned: false, createdAt: time.now), at: 0)
        trimUnpinned()
        persistEntries()
    }

    public func togglePin(_ id: UUID) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].isPinned.toggle()
        persistEntries()
    }

    public func remove(_ id: UUID) {
        entries.removeAll { $0.id == id }
        persistEntries()
    }

    /// Removes all unpinned entries while preserving pinned favorites.
    public func clearUnpinned() {
        entries.removeAll { !$0.isPinned }
        persistEntries()
    }

    public func addSnippet(title: String, body: String) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty, !cleanBody.isEmpty else { return }
        snippets.insert(TextSnippet(title: cleanTitle, body: cleanBody), at: 0)
        persistSnippets()
    }

    public func removeSnippet(_ id: UUID) {
        snippets.removeAll { $0.id == id }
        persistSnippets()
    }

    private func trimUnpinned() {
        var unpinnedCount = 0
        entries = entries.filter { entry in
            if entry.isPinned { return true }
            unpinnedCount += 1
            return unpinnedCount <= Self.maxUnpinned
        }
    }

    private func persistEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: Self.entriesKey)
        }
    }

    private func persistSnippets() {
        if let data = try? JSONEncoder().encode(snippets) {
            defaults.set(data, forKey: Self.snippetsKey)
        }
    }
}
