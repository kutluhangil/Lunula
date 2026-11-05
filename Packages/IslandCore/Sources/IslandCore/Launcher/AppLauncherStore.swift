import Foundation
import Observation

public struct PinnedApp: Identifiable, Codable, Equatable, Sendable {
    public var id: String { path }
    public var name: String
    public var path: String

    public init(name: String, path: String) {
        self.name = name
        self.path = path
    }
}

public struct PinnedShortcut: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }

    public var runURL: URL? {
        guard let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: "shortcuts://run-shortcut?name=\(encoded)")
    }
}

/// Persists pinned applications and Apple Shortcuts for one-tap launching from the expanded island.
@MainActor @Observable public final class AppLauncherStore {
    static let appsKey = "launcher.apps.v1"
    static let shortcutsKey = "launcher.shortcuts.v1"

    public static let defaultApps: [PinnedApp] = [
        PinnedApp(name: "Music", path: "/System/Applications/Music.app"),
        PinnedApp(name: "Calendar", path: "/System/Applications/Calendar.app"),
        PinnedApp(name: "Notes", path: "/System/Applications/Notes.app"),
        PinnedApp(name: "Reminders", path: "/System/Applications/Reminders.app"),
        PinnedApp(name: "Terminal", path: "/System/Applications/Utilities/Terminal.app"),
    ]

    @ObservationIgnored private let defaults: UserDefaults
    public private(set) var apps: [PinnedApp] = []
    public private(set) var shortcuts: [PinnedShortcut] = []

    public init(defaults: UserDefaults) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.appsKey),
            let decoded = try? JSONDecoder().decode([PinnedApp].self, from: data)
        {
            apps = decoded
        } else {
            apps = Self.defaultApps
        }
        if let data = defaults.data(forKey: Self.shortcutsKey),
            let decoded = try? JSONDecoder().decode([PinnedShortcut].self, from: data)
        {
            shortcuts = decoded
        }
    }

    public func addApp(name: String, path: String) {
        guard !path.isEmpty, !apps.contains(where: { $0.path == path }) else { return }
        apps.append(PinnedApp(name: name, path: path))
        persistApps()
    }

    public func removeApp(path: String) {
        apps.removeAll { $0.path == path }
        persistApps()
    }

    public func addShortcut(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !shortcuts.contains(where: { $0.name == trimmed }) else { return }
        shortcuts.append(PinnedShortcut(name: trimmed))
        persistShortcuts()
    }

    public func removeShortcut(_ id: UUID) {
        shortcuts.removeAll { $0.id == id }
        persistShortcuts()
    }

    private func persistApps() {
        if let data = try? JSONEncoder().encode(apps) {
            defaults.set(data, forKey: Self.appsKey)
        }
    }

    private func persistShortcuts() {
        if let data = try? JSONEncoder().encode(shortcuts) {
            defaults.set(data, forKey: Self.shortcutsKey)
        }
    }
}
