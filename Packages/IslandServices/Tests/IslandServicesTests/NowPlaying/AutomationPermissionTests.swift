import Foundation
import IslandCore
import Testing

@testable import IslandServices

@Suite struct AutomationPermissionTests {
    @Test func statusCodesMapToPermission() {
        #expect(AutomationPermissionChecker.permission(forStatus: noErr) == .granted)
        #expect(AutomationPermissionChecker.permission(forStatus: -1744) == .needsConsent)
        #expect(AutomationPermissionChecker.permission(forStatus: -1743) == .denied)
        #expect(AutomationPermissionChecker.permission(forStatus: -600) == .notRunning)
    }

    @MainActor @Test func grantingConsentStartsSnapshotQuery() async {
        let music = FakeSource(.music, playing: true)
        let perms = FakePermissions([.music: .needsConsent], afterRequest: .granted)
        let c = NowPlayingCoordinator.make(sources: [music], permissions: perms)
        c.start()
        await settle()
        await c.requestConsent(for: .music)
        await settle()
        #expect(c.pendingConsent == nil && music.queryCount == 1 && c.snapshot != nil)
    }
}
