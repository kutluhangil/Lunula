import Foundation

public enum TemperatureUnit: String, Codable, Sendable { case celsius, fahrenheit }

public enum SpeedUnit: String, Codable, Sendable { case kilometersPerHour, milesPerHour }

/// Locale-independent formatting, so output is identical on macOS and Linux.
public enum IslandFormat {
    /// Remaining time, rounded up: 59.2 s shows "1:00". Negative values clamp to "0:00".
    public static func countdown(_ remaining: TimeInterval) -> String {
        clock(whole(max(0, remaining).rounded(.up)))
    }

    /// Elapsed track time, rounded down.
    public static func trackTime(_ seconds: TimeInterval) -> String {
        clock(whole(max(0, seconds).rounded(.down)))
    }

    /// Rounds half away from zero; Int conversion drops the negative zero.
    public static func temperature(celsius: Double, unit: TemperatureUnit) -> String {
        guard celsius.isFinite else { return "--°" }
        let value = unit == .celsius ? celsius : celsius * 9 / 5 + 32
        return "\(whole(value.rounded()))°"
    }

    /// Untrusted input (AppleScript): non-finite becomes 0, huge values clamp (about 31 years) instead of trapping.
    private static func whole(_ v: Double) -> Int {
        v.isFinite ? Int(min(max(v, -1e9), 1e9)) : 0
    }

    private static func clock(_ total: Int) -> String {
        let h = total / 3600
        let m = total % 3600 / 60
        let s = total % 60
        let ss = s < 10 ? "0\(s)" : "\(s)"
        guard h > 0 else { return "\(m):\(ss)" }
        return "\(h):\(m < 10 ? "0" : "")\(m):\(ss)"
    }
}
