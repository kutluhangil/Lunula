import Foundation
import Testing

@Suite struct AppBundleTests {
    @Test func appIsAgentWithoutDockIcon() {
        #expect(Bundle.main.object(forInfoDictionaryKey: "LSUIElement") as? Bool == true)
    }

    @Test func urlSchemeIsRegistered() throws {
        let types = try #require(
            Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]])
        let schemes = types.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
        #expect(schemes.contains("lunula"))
    }

    @Test func everyUsageDescriptionIsPresent() {
        for key in [
            "NSAppleEventsUsageDescription", "NSCalendarsFullAccessUsageDescription",
            "NSLocationUsageDescription", "NSLocationWhenInUseUsageDescription",
        ] {
            #expect((Bundle.main.object(forInfoDictionaryKey: key) as? String)?.isEmpty == false, "\(key)")
        }
    }
}
