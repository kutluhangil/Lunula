import IslandCore

/// Spec §6.4 daylight tints; used on the home page only, at half the ambient halo intensity.
public enum Daylight {
    public static let intensityScale = 0.5

    public static func color(_ phase: DaylightPhase) -> RGBAColor {
        switch phase {
        case .dawn: RGBAColor(red: 0xFF / 255, green: 0xB3 / 255, blue: 0xC1 / 255)
        case .day: RGBAColor(red: 1, green: 1, blue: 1)
        case .dusk: RGBAColor(red: 0xFF / 255, green: 0x9F / 255, blue: 0x43 / 255)
        case .night: RGBAColor(red: 0x6E / 255, green: 0x8B / 255, blue: 0xFF / 255)
        }
    }
}
