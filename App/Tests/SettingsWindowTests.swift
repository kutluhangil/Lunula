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
    @Test func windowHasExactDimensionsAndBasaltBackground() {
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let c = SettingsWindowController(
            settings: settings,
            launchAtLogin: LaunchAtLoginService(item: FakeLoginItem(status: .notRegistered))
        )
        guard let window = c.window else {
            Issue.record("Window should exist")
            return
        }
        #expect(window.contentRect(forFrameRect: window.frame).width == 680)
        #expect(window.contentRect(forFrameRect: window.frame).height == 540)
        #expect(window.titlebarAppearsTransparent == true)
        #expect(window.styleMask.contains(.fullSizeContentView))
    }

    @Test func fiveTabsAreDefinedWithLocalizedTitlesAndSymbols() {
        #expect(
            SettingsTabID.allCases.map(\.rawValue) == [
                "general", "appearance", "activities", "tools", "about",
            ])
        for tab in SettingsTabID.allCases {
            #expect(!tab.shortTitle.isEmpty && !tab.shortTitle.hasPrefix("settings.tab."))
            #expect(!tab.symbol.isEmpty)
        }
    }

    @Test func allTabsProducesAllFiveTabs() {
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let tabs = SettingsTab.allTabs(
            settings: settings,
            launchAtLogin: LaunchAtLoginService(item: FakeLoginItem(status: .notRegistered))
        )
        #expect(tabs.map(\.id) == ["general", "appearance", "activities", "tools", "about"])
    }

    @Test func agentHookSnippetAndTestActivityURLAreValid() throws {
        let url = try #require(ActivitiesSettingsView.testActivityURL)
        guard case .success(.showActivity(let req)) = IslandURLParser.parse(url) else {
            Issue.record("Expected valid showActivity URL")
            return
        }
        #expect(req.id == "lunula-test" && req.title == "Claude Code")
        let data = Data(ActivitiesSettingsView.claudeCodeHookSnippet.utf8)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["hooks"] != nil)
    }
}
