import AppKit
import IslandCore
import SwiftUI

public enum Palette {
    public static let obsidianRGBA = RGBAColor(red: 0, green: 0, blue: 0, alpha: 1)

    public static let obsidian = color(obsidianRGBA)
    public static let inkRaised = Color(.sRGB, red: 0x11 / 255, green: 0x11 / 255, blue: 0x13 / 255)
    public static let inkPressed = Color(.sRGB, red: 0x1C / 255, green: 0x1C / 255, blue: 0x1F / 255)
    public static let hairline = Color.white.opacity(0.10)
    public static let textPrimary = Color(.sRGB, red: 0xF5 / 255, green: 0xF5 / 255, blue: 0xF7 / 255)
    public static let textSecondary = Color.white.opacity(0.62)
    public static let textTertiary = Color.white.opacity(0.38)
    public static let signalGreen = Color(nsColor: .systemGreen)
    public static let signalOrange = Color(nsColor: .systemOrange)
    public static let signalRed = Color(nsColor: .systemRed)

    public static func tint(_ tint: SignalTint) -> Color {
        switch tint {
        case .accent(let rgba): color(rgba)
        case .green: signalGreen
        case .orange: signalOrange
        case .red: signalRed
        case .neutral: textPrimary
        }
    }

    public static func color(_ rgba: RGBAColor) -> Color {
        Color(.sRGB, red: rgba.red, green: rgba.green, blue: rgba.blue, opacity: rgba.alpha)
    }
}
