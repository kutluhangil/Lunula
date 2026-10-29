import Foundation
import Observation
import ServiceManagement

public protocol LoginItemControlling: AnyObject {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
}

extension SMAppService: LoginItemControlling {}

/// Launch at login via SMAppService. App Review 2.4.5(iii): registers only when the user turns it on.
@MainActor @Observable public final class LaunchAtLoginService {
    @ObservationIgnored private let item: LoginItemControlling
    public private(set) var isEnabled: Bool
    public private(set) var requiresApproval: Bool

    public init(item: LoginItemControlling = SMAppService.mainApp) {
        self.item = item
        isEnabled = item.status == .enabled
        requiresApproval = item.status == .requiresApproval
    }

    public func setEnabled(_ on: Bool) throws {
        defer { refresh() }
        if on { try item.register() } else { try item.unregister() }
    }

    /// Status can change in System Settings while the app runs; call when the settings window appears.
    public func refresh() {
        isEnabled = item.status == .enabled
        requiresApproval = item.status == .requiresApproval
    }

    public func openSystemSettings() { SMAppService.openSystemSettingsLoginItems() }
}
