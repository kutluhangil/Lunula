import Foundation
import IslandCore
import IslandServices
import ServiceManagement
import Testing

@testable import Lunula

private final class RecordingLoginItem: LoginItemControlling {
    var status: SMAppService.Status = .notRegistered
    private(set) var calls: [String] = []
    func register() throws { calls.append("register") }
    func unregister() throws { calls.append("unregister") }
}

@MainActor @Suite struct OnboardingTests {
    @Test func shouldShowOnlyBeforeCompletion() {
        var s = IslandSettings()
        #expect(OnboardingWindowController.shouldShow(s))
        s.hasCompletedOnboarding = true
        #expect(!OnboardingWindowController.shouldShow(s))
    }

    @Test func finishingMarksCompletedAndDoesNotRegisterLoginItemUnlessToggled() {
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let item = RecordingLoginItem()
        var finished = false
        let c = OnboardingWindowController(
            settings: settings, launchAtLogin: LaunchAtLoginService(item: item), onFinish: { finished = true })
        c.finish(launchAtLogin: false)
        #expect(settings.settings.hasCompletedOnboarding && finished && item.calls.isEmpty)
    }
}
