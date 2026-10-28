import Foundation
import Observation

@MainActor @Observable
public final class SettingsStore {
    public private(set) var settings: IslandSettings
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let key: String

    public init(defaults: UserDefaults, key: String = "settings.v1") {
        self.defaults = defaults
        self.key = key
        settings =
            defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(IslandSettings.self, from: $0) }
            ?? .default
    }

    public func update(_ mutate: (inout IslandSettings) -> Void) {
        mutate(&settings)
        do {
            defaults.set(try JSONEncoder().encode(settings), forKey: key)
        } catch {
            assertionFailure("Settings could not be encoded: \(error)")
        }
    }
}
