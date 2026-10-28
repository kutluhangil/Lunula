import Testing

@testable import IslandCore

@Suite struct PackageSmokeTests {
    @Test func moduleVersionIsSet() {
        #expect(IslandCoreModule.version == "0.1.0")
    }
}
