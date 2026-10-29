import AppKit
import Foundation
import IslandCore
import IslandServices
import ServiceManagement
import Testing

@testable import Lunula

private final class FakeLoginItem: LoginItemControlling {
    var status: SMAppService.Status
    init(status: SMAppService.Status) { self.status = status }
    func register() throws {}
    func unregister() throws {}
}

@MainActor @Suite struct SettingsWindowTests {
    @Test func windowHasGeneralAndAboutTabs() {
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let c = SettingsWindowController(
            tabs: SettingsTab.baseTabs(
                settings: settings, launchAtLogin: LaunchAtLoginService(item: FakeLoginItem(status: .notRegistered))))
        #expect(
            (c.contentViewController as? NSTabViewController)?.tabViewItems.map { $0.identifier as? String } == [
                "general", "about",
            ])
    }

    @Test func tabStyleIsToolbar() {
        let c = SettingsWindowController(tabs: [])
        #expect((c.contentViewController as? NSTabViewController)?.tabStyle == .toolbar)
    }
}
