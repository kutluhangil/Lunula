import Foundation

/// Time-of-day tint for the home halo: ±45 min around sunrise and sunset, day between, night outside.
public enum DaylightPhase: Equatable, Sendable {
    case dawn, day, dusk, night

    static let window: TimeInterval = 45 * 60

    public static func phase(now: Date, sunrise: Date?, sunset: Date?, isDaylight: Bool) -> DaylightPhase {
        guard let sunrise, let sunset else { return isDaylight ? .day : .night }
        if abs(now.timeIntervalSince(sunrise)) <= window { return .dawn }
        if abs(now.timeIntervalSince(sunset)) <= window { return .dusk }
        return now > sunrise && now < sunset ? .day : .night
    }
}
