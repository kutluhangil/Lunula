import AppKit
import IslandDesign
import SwiftUI

public enum PermissionState: Equatable, Sendable {
    case notRequested, granted, denied, unavailable, systemManaged
}

public enum ExtraPermissionKind: String, CaseIterable, Sendable {
    case reminders
    case camera
    case audioTap
    case screenCapture
    case spotify
}

/// One privacy permission badge: status dot, status label and direct action button.
public struct PermissionRow: View {
    public enum Action: Equatable, Sendable {
        case request, openSettings
    }

    public static func action(for state: PermissionState) -> Action? {
        switch state {
        case .notRequested: .request
        case .denied, .systemManaged: .openSettings
        case .granted, .unavailable: nil
        }
    }

    public let name: String?
    public let state: PermissionState
    public let onRequest: @MainActor () -> Void
    public let onOpenSettings: @MainActor () -> Void

    public init(
        name: String? = nil,
        state: PermissionState,
        onRequest: @escaping @MainActor () -> Void = {},
        onOpenSettings: @escaping @MainActor () -> Void = {}
    ) {
        self.name = name
        self.state = state
        self.onRequest = onRequest
        self.onOpenSettings = onOpenSettings
    }

    private var dotColor: Color {
        switch state {
        case .granted: Color(red: 0x32 / 255, green: 0xD7 / 255, blue: 0x4B / 255)
        case .notRequested, .systemManaged: Palette.amberGold
        case .denied: Color(red: 0xFF / 255, green: 0x45 / 255, blue: 0x3A / 255)
        case .unavailable: Palette.textTertiary
        }
    }

    private var statusText: String {
        let text: String
        switch state {
        case .granted: text = String(localized: "permission.row.granted")
        case .notRequested: text = String(localized: "permission.row.notRequested")
        case .denied: text = String(localized: "permission.row.denied")
        case .unavailable: text = String(localized: "permission.row.unavailable")
        case .systemManaged: text = String(localized: "permission.row.systemManaged")
        }
        if let name = name, !name.isEmpty {
            return "\(name) · \(text)"
        }
        return text
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)

            Text(statusText)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Palette.textSecondary)

            if state == .notRequested {
                Button(action: onRequest) {
                    Text(String(localized: "permission.row.allow"))
                }
                .buttonStyle(.lunulaBadge)
            } else if state == .denied || state == .systemManaged {
                Button(action: onOpenSettings) {
                    HStack(spacing: 4) {
                        Text(String(localized: "permission.row.openSettings"))
                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 9, weight: .semibold))
                    }
                }
                .buttonStyle(.lunulaBadge)
            }
        }
        .frame(minHeight: 22)
    }

    /// System Settings › Privacy & Security panes.
    public static func settingsURL(_ pane: String) -> URL {
        URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)")!
    }

    public static func extraSettingsURL(_ kind: ExtraPermissionKind) -> URL {
        switch kind {
        case .reminders: settingsURL("Privacy_Reminders")
        case .camera: settingsURL("Privacy_Camera")
        case .audioTap: settingsURL("Privacy_AudioCapture")
        case .screenCapture: settingsURL("Privacy_ScreenCapture")
        case .spotify: settingsURL("Privacy_Automation")
        }
    }
}
