import Foundation
import Testing

/// Reads the source String Catalogs of the app and the packages. Lives in a package test target: the sandboxed app
/// test host cannot read the source tree.
@Suite struct LocalizationTests {
    // #filePath is …/Packages/IslandFeatures/Tests/IslandFeaturesTests/Localization/<file>; six levels up is the repo.
    static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    static let catalogs = [
        "App/Resources/Localizable.xcstrings", "App/Resources/InfoPlist.xcstrings",
        "App/Resources/AppShortcuts.xcstrings",
        "Packages/IslandFeatures/Sources/IslandFeatures/Resources/Localizable.xcstrings",
    ]

    /// (catalog, key, language, value or nil when missing/untranslated)
    static func entries() throws -> [(String, String, String, String?)] {
        try catalogs.flatMap { path -> [(String, String, String, String?)] in
            let data = try Data(contentsOf: root.appending(path: path))
            let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
            let strings = json["strings"] as? [String: [String: Any]] ?? [:]
            return strings.flatMap { key, entry in
                ["en", "tr"].map { lang in
                    let unit =
                        ((entry["localizations"] as? [String: Any])?[lang] as? [String: Any])?["stringUnit"]
                        as? [String: Any]
                    let translated = unit?["state"] as? String == "translated"
                    return (path, key, lang, translated ? unit?["value"] as? String : nil)
                }
            }
        }
    }

    @Test func everyStringHasTurkishAndEnglish() throws {
        let missing = try Self.entries().filter { $0.3?.isEmpty ?? true }.map { "\($0.0): \($0.1) [\($0.2)]" }
        #expect(missing.isEmpty, "\(missing)")
    }

    @Test func noStringContainsExclamationMark() throws {
        let loud = try Self.entries().filter { $0.3?.contains("!") == true }.map { "\($0.1) [\($0.2)]" }
        #expect(loud.isEmpty, "\(loud)")
    }
}
