import AppKit
import SwiftUI

enum PermissionState: Equatable { case notRequested, granted, denied, unavailable }

/// One privacy permission: its state and the single action that makes sense for it.
struct PermissionRow: View {
    enum Action: Equatable { case request, openSettings }

    let titleKey: LocalizedStringResource
    let state: PermissionState
    let onRequest: @MainActor () -> Void
    let onOpenSettings: @MainActor () -> Void

    static func action(for state: PermissionState) -> Action? {
        switch state {
        case .notRequested: .request
        case .denied: .openSettings
        case .granted, .unavailable: nil
        }
    }

    var body: some View {
        LabeledContent {
            switch Self.action(for: state) {
            case .request: Button("permission.row.allow", action: onRequest)
            case .openSettings: Button("settings.general.openLoginItems", action: onOpenSettings)
            case nil:
                Text(state == .granted ? "permission.row.granted" : "permission.row.unavailable").foregroundStyle(
                    .secondary)
            }
        } label: {
            Text(titleKey)
        }
    }

    /// System Settings › Privacy & Security panes.
    static func settingsURL(_ pane: String) -> URL {
        URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)")!
    }
}
