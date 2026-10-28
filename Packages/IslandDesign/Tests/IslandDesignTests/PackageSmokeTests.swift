import Testing

@testable import IslandDesign

@Suite struct PackageSmokeTests {
    @Test func moduleVersionIsSet() {
        #expect(IslandDesignModule.version == "0.1.0")
    }
}
