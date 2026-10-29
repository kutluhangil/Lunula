import AppKit

enum CustomSymbol {
    static let fallback = "sparkle"

    /// Unknown SF Symbol names from URLs or Shortcuts fall back instead of drawing nothing.
    static func resolve(_ name: String?) -> String {
        guard let name, NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil else { return fallback }
        return name
    }
}
