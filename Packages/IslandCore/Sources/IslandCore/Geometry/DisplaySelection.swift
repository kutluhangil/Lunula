import Foundation

public enum DisplayMode: String, Codable, Sendable, CaseIterable {
    case notchedOnly, allDisplays, mainDisplay
}

public enum DisplaySelection {
    public static func screens(from screens: [ScreenDescriptor], mode: DisplayMode) -> [ScreenDescriptor] {
        switch mode {
        case .allDisplays:
            return screens
        case .mainDisplay:
            return screens.filter(\.isMain)
        case .notchedOnly:
            let notched = screens.filter { NotchGeometry.metrics(for: $0).hasHardwareNotch }
            return notched.isEmpty ? screens.filter(\.isMain) : notched
        }
    }
}
