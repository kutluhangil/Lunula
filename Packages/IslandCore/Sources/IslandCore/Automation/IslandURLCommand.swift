import Foundation

public enum CustomActivityLimits {
    public static let maxIDLength = 64
    public static let maxTitleLength = 80
    public static let maxSubtitleLength = 120
    public static let maxLifetime: TimeInterval = 28_800
    public static let maxConcurrent = 3
    public static let timerMinutes: ClosedRange<Double> = 1...600
}

public struct CustomActivityRequest: Equatable, Sendable {
    public var id: String
    public var title: String
    public var subtitle: String?
    public var symbol: String?
    public var accent: RGBAColor?
    public var progress: Double?
    public var duration: TimeInterval?

    public init(
        id: String, title: String, subtitle: String?, symbol: String?, accent: RGBAColor?, progress: Double?,
        duration: TimeInterval?
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.accent = accent
        self.progress = progress
        self.duration = duration
    }
}

public enum IslandURLCommand: Equatable, Sendable {
    case showActivity(CustomActivityRequest)
    case endActivity(id: String)
    case startTimer(minutes: Double)
    case toggleIsland
}

public enum IslandURLError: Error, Equatable, Sendable {
    case wrongScheme
    case unknownCommand(String)
    case missingParameter(String)
    case invalidParameter(String)
    case rateLimited
}

extension CustomActivityRequest {
    /// Single validation point shared by the URL parser and App Intents.
    public static func make(
        id: String?, title: String?, subtitle: String?, symbol: String?, accentHex: String?, progress: Double?,
        duration: Double?
    ) -> Result<CustomActivityRequest, IslandURLError> {
        if let failure = validateID(id) { return .failure(failure) }
        guard let id else { return .failure(.missingParameter("id")) }
        let cleanTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !cleanTitle.isEmpty else { return .failure(.missingParameter("title")) }
        var accent: RGBAColor?
        if let accentHex {
            guard let color = RGBAColor(hex: accentHex) else { return .failure(.invalidParameter("accent")) }
            accent = color
        }
        var clampedProgress: Double?
        if let progress {
            guard !progress.isNaN else { return .failure(.invalidParameter("progress")) }
            clampedProgress = min(max(progress, 0), 1)
        }
        if let duration {
            guard (1...CustomActivityLimits.maxLifetime).contains(duration) else {
                return .failure(.invalidParameter("duration"))
            }
        }
        let cleanSubtitle = subtitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSymbol = symbol?.trimmingCharacters(in: .whitespacesAndNewlines)
        return .success(
            CustomActivityRequest(
                id: id,
                title: truncated(cleanTitle, to: CustomActivityLimits.maxTitleLength),
                subtitle: cleanSubtitle.flatMap {
                    $0.isEmpty ? nil : truncated($0, to: CustomActivityLimits.maxSubtitleLength)
                },
                symbol: cleanSymbol.flatMap { $0.isEmpty ? nil : $0 },
                accent: accent, progress: clampedProgress, duration: duration))
    }

    /// Returns the error for a missing or malformed id, nil when valid.
    static func validateID(_ id: String?) -> IslandURLError? {
        guard let id, !id.isEmpty else { return .missingParameter("id") }
        guard id.count <= CustomActivityLimits.maxIDLength, id.allSatisfy(isIDCharacter) else {
            return .invalidParameter("id")
        }
        return nil
    }

    private static func isIDCharacter(_ c: Character) -> Bool {
        c.isASCII && (c.isLetter || c.isNumber || c == "." || c == "_" || c == "-")
    }

    private static func truncated(_ s: String, to max: Int) -> String {
        s.count <= max ? s : String(s.prefix(max - 1)) + "…"
    }
}
