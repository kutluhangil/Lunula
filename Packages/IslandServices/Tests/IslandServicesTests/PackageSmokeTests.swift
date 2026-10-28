import Testing

@testable import IslandServices

@Suite struct PackageSmokeTests {
    @Test func moduleVersionIsSet() {
        #expect(IslandServicesModule.version == "0.1.0")
    }
}
