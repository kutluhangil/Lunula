import Testing

@testable import IslandFeatures

@Suite struct PackageSmokeTests {
    @Test func moduleVersionIsSet() {
        #expect(IslandFeaturesModule.version == "0.1.0")
    }
}
