import Foundation

public enum DisplayMode: String, Codable, Sendable, CaseIterable {
    case notchedOnly, allDisplays, mainDisplay
}

public enum DisplaySelection {
    public static func screens(from screens: [ScreenDescriptor], mode: DisplayMode) -> [ScreenDescriptor] {
        let main = screens.contains(where: \.isMain) ? screens.filter(\.isMain) : Array(screens.prefix(1))
        switch mode {
        case .allDisplays:
            return screens
        case .mainDisplay:
            return main
        case .notchedOnly:
            let notched = screens.filter { NotchGeometry.metrics(for: $0).hasHardwareNotch }
            return notched.isEmpty ? main : notched
        }
    }
}
