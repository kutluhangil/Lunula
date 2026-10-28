import Foundation
import Testing

@testable import IslandCore

@MainActor @Suite struct SettingsStoreTests {
    func freshDefaults() -> UserDefaults { UserDefaults(suiteName: "test.\(UUID().uuidString)")! }

    @Test func storePersistsAcrossInstances() {
        let d = freshDefaults()
        SettingsStore(defaults: d).update { $0.soundsEnabled = false }
        #expect(SettingsStore(defaults: d).settings.soundsEnabled == false)
    }

    @Test func corruptDataFallsBackToDefaults() {
        let d = freshDefaults()
        d.set(Data("not json".utf8), forKey: "settings.v1")
        #expect(SettingsStore(defaults: d).settings == .default)
    }
}
