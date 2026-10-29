import Foundation
import ServiceManagement
import Testing

@testable import IslandServices

final class FakeLoginItem: LoginItemControlling {
    var status: SMAppService.Status
    private(set) var calls: [String] = []

    init(status: SMAppService.Status) { self.status = status }

    func register() throws {
        calls.append("register")
        status = .enabled
    }

    func unregister() throws {
        calls.append("unregister")
        status = .notRegistered
    }
}

@MainActor @Suite struct LaunchAtLoginServiceTests {
    @Test func enablingRegistersAndDisablingUnregisters() throws {
        let fake = FakeLoginItem(status: .notRegistered)
        let s = LaunchAtLoginService(item: fake)
        try s.setEnabled(true)
        try s.setEnabled(false)
        #expect(fake.calls == ["register", "unregister"])
    }

    @Test func requiresApprovalIsSurfaced() {
        #expect(LaunchAtLoginService(item: FakeLoginItem(status: .requiresApproval)).requiresApproval)
    }
}
