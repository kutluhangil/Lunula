public struct RGBAColor: Hashable, Codable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Parses `RRGGBB` with or without a leading `#`. Alpha is always 1.
    public init?(hex: String) {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255)
    }

    public var hexString: String {
        func byte(_ v: Double) -> String {
            let n = Int((min(max(v, 0), 1) * 255).rounded())
            return (n < 16 ? "0" : "") + String(n, radix: 16, uppercase: true)
        }
        return "#" + byte(red) + byte(green) + byte(blue)
    }
}
